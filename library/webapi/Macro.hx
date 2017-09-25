package webapi;

import sys.io.File;
import haxe.io.Path;
import stdlib.FileSystem;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Printer;
using stdlib.StringTools;
using haxe.macro.TypeTools;
using webapi.MacroTools;
using stdlib.Lambda;

private typedef ClassTree =
{
	var name : String;
	var children : Array<ClassTree>;
	var classes:Array<ClassType>;
}

private typedef Method =
{
	var name: String;
	var args: Array<FunctionArg>;
	var ret: Null<ComplexType>;
	var pos: Position;
}

class Macro
{
	public static var output = "gen";
	public static var aggregatorClassName = "Client";
	public static var aggregatorTopPackage = "";
	public static var modulesToCopyToOutput = [];
	
	public static function setOutput(s:String) : Void
	{
		output = s;
	}
	
	public static function setAggregatorClassName(s:String) : Void
	{
		aggregatorClassName = s;
	}
	
	public static function setAggregatorTopPackage(s:String) : Void
	{
		aggregatorTopPackage = s;
	}
	
	public static function copy(module:String) : Void
	{
		modulesToCopyToOutput.push(module);
	}
	
	public static function generateClientAPI() : Void
	{
		if (!Context.defined("neko") && !Context.defined("php")) return;
		
		if (!Context.defined("display"))
		{
			Context.onGenerate(function(types:Array<Type>)
			{
				var root : ClassTree =
				{
					name: "",
					children: [],
					classes: []
				};
				
				for (type in types)
				{
					switch (type)
					{
						case Type.TInst(t, params):
							var klass = t.get();
							if (klass.meta.has("controller")) addClassToTree(root, klass);
						default:
					}
				}
				
				renderClassTree(root, []);
				
				for (module in modulesToCopyToOutput)
				{
					saveTextFileIfNeed(Path.join([output].concat(module.split("."))) + ".hx", File.getContent(Context.resolvePath(module.replace(".", "/") + ".hx")));
				}
			});
		}
	}
	
	static function addClassToTree(tree:ClassTree, klass:ClassType)
	{
		for (i in 0...klass.pack.length)
		{
			var p = klass.pack[i];
			
			var c = null;
			for (t in tree.children) if (t.name == p) { c = t; break; }
			if (c == null)
			{
				c =
				({
					name: p,
					children: [],
					classes: []
				});
				tree.children.push(c);
			}
			tree = c;
		}
		tree.classes.push(klass);
	}
	
	static function renderClassTree(tree:ClassTree, pack:Array<String>)
	{
		for (child in tree.children) renderClassTree(child, tree.name != "" ? pack.concat([tree.name]) : pack);
		
		var constructorCode = new Array<Expr>();
		var fields = new Array<Field>();
		
		for (child in tree.children)
		{
			var newKlass = MacroTools.makeTypePath(pack.concat([child.name]), aggregatorClassName);
			
			constructorCode.push(macro $i{"this." + child.name} = new $newKlass(baseUrl));
			
			fields.push
			({
				name: child.name,
				kind: FieldType.FProp("default", "null", ComplexType.TPath(newKlass)),
				access: [ Access.APublic ],
				pos: null
			});
		}
		
		for (klass in tree.classes)
		{
			var newKlass = MacroTools.makeTypePath(pack.concat([tree.name]), capitalize(klass.name));
			var fieldName = decapitalize(klass.name);
			
			constructorCode.push(macro $i{"this." + fieldName} = new $newKlass(baseUrl));
			
			fields.push
			({
				name: fieldName,
				kind: FieldType.FProp("default", "null", ComplexType.TPath(newKlass)),
				access: [ Access.APublic ],
				pos: null
			});
			
			generateRequestorClass(klass);
		}
		
		var constructor = "new".makeMethod([ "baseUrl".toArg(macro : String) ], macro : Void, ExprDef.EBlock(constructorCode).at());
		
		if ((pack.join(".") + ".").startsWith(aggregatorTopPackage + "."))
		{
			generateClass(pack, aggregatorClassName, fields.concat([constructor]));
		}
	}
	
	static function generateRequestorClass(serverClass:ClassType) : Void
	{
		var requesterField = "requester".makeVar(macro : webapi.Requester);
		
		var serverActions = getMetaMarkedMethods("action", serverClass);
		var clientActions = serverActions.map(function(method:Method)
		{
			var ret = method.ret;
			
			var callParams = [ 
				serverClass.pack.concat([serverClass.name, method.name]).join("/").toExpr(method.pos),
				Lambda.map(method.args, function(a) return Context.parse(a.name, method.pos)).toArray()
			];
			var callExpr = macro { return cast this.requester.request($a{callParams}); };
			var retExpr = MacroTools.isVoid(ret)
						? macro : js.Promise<{}>
						: macro : js.Promise<$ret>;
			return method.name.makeMethod(method.args, retExpr, callExpr);
		});
		
		var constructor = "new".makeMethod([ "baseUrl".toArg(macro : String) ], macro : Void, macro { this.requester = new webapi.Requester(baseUrl); });
		
		generateClass(serverClass.pack, serverClass.name, [requesterField].concat([constructor]).concat(clientActions));
	}
	
	static function generateClass(pack:Array<String>, className:String, fields:Array<Field>)
	{
		var dstModulePath = output + "/" + pack.join("/") + (pack.length > 0 ? "/" : "") + className + ".hx";
		
		var printer = new Printer();
		var renderedClassFields = fields.map(function(f) return printer.printField(f) + ";\n").join("\n");
		renderedClassFields = StringTools.replace(renderedClassFields, "};", "}");
		renderedClassFields = StringTools.replace(renderedClassFields, "StdTypes.Void", "Void");
		renderedClassFields = "\t" + renderedClassFields.rtrim().replace("\n", "\n\t") + "\n";
		
		var s = "// This is autogenerated file. Do not edit!\n"
			  + "\n"
			  + "package " + pack.join(".") + ";\n"
			  + "\n"
			  + "class " + className + "\n"
			  + "{\n"
			  + renderedClassFields
			  + "}\n";
		
		
		saveTextFileIfNeed(dstModulePath, s);
	}
	
	static function getMetaMarkedMethods(metaMark:String, klass:ClassType) : Array<Method>
	{
		var r = new Array<Method>();
		
		for (field in klass.fields.get())
		{
			if (field.meta.has(metaMark))
			{
				var typedFieldExpr = field.expr();
				if (typedFieldExpr != null)
				{
					var fieldExpr = Context.getTypedExpr(field.expr());
					if (fieldExpr != null)
					{
						if (fieldExpr.expr != null)
						{
							switch (fieldExpr.expr)
							{
								case ExprDef.EFunction(name, f):
										r.push({ name:field.name, args:f.args, ret:f.ret, pos:klass.pos });
								
								default:
									Context.error("Use @" + metaMark + " for methods only.", field.pos);
							}
						}
					}
				}
				else
				{
					switch (field.type)
					{
						case Type.TFun(args, ret):
							r.push({ name:field.name, args:args.funArgsToFunctionArgs(), ret:ret.toComplexType(), pos:klass.pos });
						
						default:
							Context.error("Use @" + metaMark + " for methods only.", field.pos);
					}
				}
			}
		}
		
		if (klass.superClass != null)
		{
			r = r.concat(getMetaMarkedMethods(metaMark, klass.superClass.t.get()));
		}
		
		return r;	
	}
	
	static function saveTextFileIfNeed(destPath:String, text:String)
	{
		if (FileSystem.exists(destPath) && File.getContent(destPath) == text) return;
		var dir = Path.directory(destPath);
		if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);
		File.saveContent(destPath, text);
	}
	
	static function capitalize(s:String) : String return s == "" ? s : s.substr(0, 1).toUpperCase() + s.substr(1);
	static function decapitalize(s:String) : String return s == "" ? s : s.substr(0, 1).toLowerCase() + s.substr(1);
}
