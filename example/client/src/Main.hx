import js.Browser;
import v1.Client;

class Main
{
	static function main()
	{
		var client = new Client("http://webapi/index.n");
		client.archive.f2("abc", 10).then(function(n:Int)
		{
			Browser.console.log(Std.string(n));
		})
		.catchError(function(err)
		{
			Browser.console.log(Std.string(err));
		});
	}
}