// This is autogenerated file. Do not edit!

package v1;

class Client
{
	var archive(default, null) : v1.books.Archive;
	
	var trash(default, null) : v1.books.Trash;
	
	public function new(baseUrl:String):Void {
		this.archive = new v1.books.Archive(baseUrl);
		this.trash = new v1.books.Trash(baseUrl);
	}
}