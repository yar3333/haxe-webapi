class Main 
{
	static function main() 
	{
		haxe.Log.trace = webapi.Log.trace.bind("temp/webapi.log", _, _);
		
		#if neko
			
			neko.Web.cacheModule(webapi.Server.run);
			webapi.Server.run();
			
		#else
			
			webapi.Server.run();
			
		#end
 	}
}
