// This is autogenerated file. Do not edit!

package v1.books;

class Trash
{
	var requester : webapi.Requester;
	
	public function new(baseUrl:String):Void {
		this.requester = new webapi.Requester(baseUrl);
	}
	
	public function f1():js.Promise<{ }> {
		return this.requester.request("f1", []);
	}
}
