package webapi;

import stdlib.Exception;
import haxe.Unserializer;
import haxe.Json;
import haxe.rtti.Meta;
using stdlib.StringTools;

class Server
{
	public static function run() : Void
	{
		#if neko
		Sys.setCwd(Web.getCwd());
		#end
		
		var a = Web.getParams().get("a");
		if (a == null) { notFound("GET parameter 'a' must be specified."); return; }
		if (a == "") { notFound("GET parameter 'a' must not be empty."); return; }
		
		var parts = a.trim("/").split("/");
		if (parts.length < 2) { notFound("Path too short."); return; }
		
		var controllerName = parts.slice(0, parts.length - 2).join(".") + (parts.length > 2 ? "." : "") + parts[parts.length - 2].capitalize();
		var controllerClass = Type.resolveClass(controllerName);
		if (controllerClass == null) { notFound("Controller class '" + controllerName + "' not found."); return; }
		
		var typeMeta = Meta.getType(controllerClass);
		if (!Reflect.hasField(typeMeta, "controller")) { notFound("Class is not marked with '@controller' meta."); return; }
		
		var controller = Type.createInstance(controllerClass, []);
		
		var actionName = parts[parts.length - 1];
		var action = Reflect.field(controller, actionName);
		if (!Reflect.isFunction(action)) { notFound("Action method '" + actionName + "' not found."); return; }
		
		var fieldsMeta = Meta.getFields(controllerClass);
		if (!Reflect.hasField(fieldsMeta, actionName)) { notFound("Method is not marked with '@action' meta."); return; }
		var metas = Reflect.field(fieldsMeta, actionName);
		if (!Reflect.hasField(metas, "action")) { notFound("Method is not marked with '@action' meta."); return; }
		
		var data = Web.getPostData();
		var params : Dynamic;
		try params = Unserializer.run(data)
		catch (e:Dynamic) { badRequest("Post data unserialization exception: " + Exception.wrap(e).message); return; }
		
		if (!Std.is(params, Array)) { badRequest("Post data must be a serialized array."); return; }
		
		try
		{
			var result = Reflect.callMethod(controller, action, params);
			var serializedResult = stdlib.Serializer.run(result, true);
			Web.setReturnCode(200);
			Web.setHeader("Content-Type", "text/plain");
			Sys.print(serializedResult);
		}
		catch (e:Dynamic)
		{
			Web.setReturnCode(500);
			trace(Exception.string(e));
			return;
		}
	}
	
	static function notFound(s:String)
	{
		Web.setReturnCode(404);
		trace("ERROR 404: " + s);
	}
	
	static function badRequest(s:String)
	{
		Web.setReturnCode(400);
		trace("ERROR 400: " + s);
	}
}