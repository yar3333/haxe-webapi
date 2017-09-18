package v1.books;

@controller
class Archive
{
	public function new() {}
	
	@action
	public function f1() : Void
	{
		trace("Archive-f1");
	}
}