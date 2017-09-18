package v1.books;

@controller
class Archive
{
	public function new() {}
	
	@action
	public function f1(i:Int) : Void
	{
		trace("Archive-f1");
	}
	
	@action
	public function f2(s:String, n:Float) : Int
	{
		trace("Archive-f2");
		return 2;
	}
}