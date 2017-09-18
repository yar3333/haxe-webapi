package webapi;

#if (macro || display)
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

import haxe.macro.Expr;
import haxe.macro.Type;
using stdlib.StringTools;
using haxe.macro.TypeTools;

class MacroTools
{
	#if (macro || display)
	
	public static function isExtendsFrom(t:ClassType, parentClassPath:String) : Bool
	{
		while (t.superClass != null)
		{
			t = t.superClass.t.get();
			if (t.pack.join(".") + "." + t.name == parentClassPath)
			{
				return true;
			}
		}
		return false;
	}
	
	public static function getModuleType(module:String, typeName:String) : Type
	{
		for (type in Context.getModule(module))
		{
			switch(type)
			{
				case Type.TType(t, _):
					if (t.get().name == typeName) return t.get().type;
				
				default:
					return null;
			}
		}
		return null;
	}
	
	public static function getClassType(fullName:String) : ClassType
	{
		switch (Context.getType(fullName))
		{
			case Type.TInst(t, _):	return t.get();
			default:				return null;
		}
	}
	
	public static function funArgsToFunctionArgs(params:Array<{ t:Type, opt:Bool, name:String }>) : Array<FunctionArg>
	{
		var r = new Array<FunctionArg>();
		for (param in params)
		{
			r.push(toArg(param.name, param.t.toComplexType(), param.opt));
		}
		return r;
	}
	
	@:noUsing public static function makeTypePath(pack:Array<String>, name:String, ?params:Array<TypeParam>) : TypePath
	{
		return {
			  pack : pack
			, name : name
			, params : params != null ? params : []
			, sub : null
		};
	}
	
	public static function makeVar(name:String, type:ComplexType, ?expr:Expr) : Field
	{
		return {
			  name : name
			, access : []
			, kind : FieldType.FVar(type, expr)
			, pos : expr != null ? expr.pos : Context.currentPos()
		};
	}
	
	public static function makeMethod(name:String, args:Array<FunctionArg>, ret:Null<ComplexType>, expr:Expr) : Field
	{
		return {
			  name : name
			, access : [ Access.APublic ]
			, kind : FieldType.FFun({
						  args : args
						, ret : ret
						, expr : expr
						, params : []
					  })
			, pos : expr.pos
		};
	}
	
	public static function isVoid(t:Null<ComplexType>) : Bool
	{
		if (t != null)
		{
			switch (t)
			{
				case haxe.macro.Expr.ComplexType.TPath(p):
					return p.name == "Void" && p.pack.length == 0 && p.sub == null
						|| p.name == "StdTypes" && p.pack.length == 0 && p.sub == "Void";
				default:
			}
		}
		return false;
	}
	
	public static inline function toArg(name:String, ?t, opt=false, ?value) : FunctionArg
	{
		return
		{
			name: name,
			opt: opt,
			type: t,
			value: value
		};
	}
	
	public static inline function toExpr(v:Dynamic, ?pos:Position)
		return Context.makeExpr(v, pos);
		
	public static inline function at(e:ExprDef, ?pos:Position) 
		return { expr:e, pos:pos };
		
	public static inline function field(e, field, ?pos)
		return at(EField(e, field), pos);
		
	public static inline function call(e, ?params, ?pos)
		return at(ECall(e, params == null ? [] : params), pos);
		
	public static inline function toArray(exprs:Iterable<Expr>, ?pos) 
		return at(EArrayDecl(Lambda.array(exprs)), pos);
	
	#end
}