package v1.books;

@controller
class Trash
{
	public function new() {}
	
	@action
	public function f1() : Void
	{
		trace("Trash-f1");
	}
}