package webapi;

import haxe.PosInfos;
import haxe.io.Path;
import stdlib.Debug;
import sys.FileSystem;
import sys.io.File;
using StringTools;

class Log
{
	public static function trace(logFilePath:String, v:Dynamic, ?pos:PosInfos) : Void
	{
		writeToFile(logFilePath, object2string(v, pos));
	}
	
	static function object2string(v:Dynamic, pos:PosInfos) : String
	{
        if (Std.is(v, String))
		{
			var s : String = cast v;
			if (!s.startsWith('EXCEPTION:'))
			{
				s = pos.fileName + ":" + pos.lineNumber + " : " + s;
			}
			return s;
		}
        else
        if (v != null)
        {
            return "DUMP\n" + Debug.getDump(v);
        }
		return "";
	}
	
	static function writeToFile(logFilePath:String, text:String)
	{
		if (!FileSystem.exists(Path.directory(logFilePath)))
        {
            FileSystem.createDirectory(Path.directory(logFilePath));
        }
        
        var f = File.append(logFilePath);
        if (f != null)
        {
			if (text != "")
			{
				var prefix = DateTools.format(Date.now(), "%Y-%m-%d %H:%M:%S ");
				text = prefix + text.replace("\n", "\r\n\t") + "\r\n";
			}
			else
			{
				text = "\r\n";
			}
			f.writeString(text);
            f.close();
        }
	}
}
