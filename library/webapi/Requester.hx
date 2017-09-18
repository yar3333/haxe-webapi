package webapi;

import haxe.Unserializer;
import js.Promise;
import js.html.XMLHttpRequest;
import stdlib.Serializer;

class Requester
{
	var baseUrl : String;
	
	public function new(baseUrl:String)
	{
		this.baseUrl = baseUrl;
	}
	
	public function request(fullActionName:String, params:Array<Dynamic>) : Promise<Dynamic>
	{
		return post(baseUrl + "?a=" + fullActionName, Serializer.run(params, true)).then(function(r:String)
		{
			return Unserializer.run(r);
		});
	}
	
	function post(url:String, data:String) : Promise<String>
	{
		return new Promise<String>(function(resolve, reject)
		{
			var xhr = new XMLHttpRequest();
			xhr.open("POST", url, true);
			
			xhr.setRequestHeader("Content-type", "text/plain");
			
			xhr.onreadystatechange = function()
			{
				if (xhr.readyState == XMLHttpRequest.DONE)
				{
					if (xhr.status == 200) resolve(xhr.responseText);
					else                   reject({ status:xhr.status, text:xhr.responseText });
				}
			}
			
			xhr.send(data);
		});
	}
}
