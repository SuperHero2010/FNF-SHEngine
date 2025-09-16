package backend;

import flixel.math.FlxMath;
import haxe.Timer;
import Main;

/**
	Custom JSON parser optimized for chart loading with note skipping capability.
	
	This parser can skip parsing the entire "notes" array when loading charts for gameplay,
	significantly improving loading times for high note count charts (500K-1M notes).
	
	Based on H-Slice's implementation for handling massive charts efficiently.
**/
class SongJson {
	/**
		Parses given JSON-encoded `str` and returns the resulting object.

		JSON objects are parsed into anonymous structures and JSON arrays
		are parsed into `Array<Dynamic>`.

		If given `str` is not valid JSON, an exception will be thrown.

		If `str` is null, the result is unspecified.
	**/
	static public inline function parse(str:String):Dynamic {
		return new SongJson(str).doParse();
	}

	var str:String;
	var pos:Int;
	var time:Float = Timer.stamp();
	public static var skipChart:Bool = false;
	public static var log:Bool = true;

	function new(str:String) {
		this.str = str;
		this.pos = 0;
		this.bracketMode = 0;
	}

	var prepareSkipMode:Bool = false;
	var skipMode:Bool = false;
	var skipDone:Bool = false;

	function doParse():Dynamic {
		var result = parseRec();
		#if sys
	if (log) Sys.stdout().writeString('\x1b[0G$pos/${str.length}');
	#end
		while (!StringTools.isEof(c = nextChar())) {
			switch (c) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				// allow trailing whitespace
				default:
					invalidChar();
			}
		}
		if (log) Sys.print("\n");
		return result;
	}
	
	var c:Int = 0;
	var field:String = null;
	var comma:Null<Bool> = null;
	var save:Int = 0;

	var bracketMode:Int = 0; // 0, 1 = inside notes, 2 = exit notes
	var b_p:Array<Null<Int>> = [null, null, null, null]; // it's for "[", "]", "{", "}".
	var b_s:Array<Null<Int>> = [null, null, null, null]; // it's for "[", "]", "{", "}".
	final skipPattern:String = "[]{}";

	var objLayer:Int = -1;
	var obj:Array<Dynamic> = [];

	var arrLayer:Int = -1;
	var arr = [];

	var returnObject:Array<Dynamic> = [];

	function parseRec():Dynamic {
		if(obj[objLayer + 1] != null) obj[objLayer + 1] == null;
		if(arr[arrLayer + 1] != null) arr[arrLayer + 1] == null;
		c = nextChar();
		
		if (skipMode) {
			showProgress();

			for (i in 0...b_s.length) {
				b_p[i] = b_s[i] ?? str.indexOf(skipPattern.charAt(i), pos - 1);
				b_s[i] = str.indexOf(skipPattern.charAt(i), pos);
				if (b_s[i] == -1) b_s[i] = null;
			}

			if (b_s[2] < b_s[3]) {
				bracketMode = 0; // "{" < "}"
				if (b_s[1] < b_s[2]) bracketMode = 2; // "]" < "{"
			}
			else if (b_s[2] == null || b_s[3] < b_s[2]) {
				bracketMode = 1; // found '{' && "}" < "{"
				if (b_s[2] == null) {
					if (b_p[3] < b_s[1]) bracketMode = 2; // old "}" < new "]"
				} 
			}
			
			if (b_s[1] != null && (b_s[2] != null || b_s[3] != null)) {
				switch (bracketMode) {
					case 0, 1:
						pos = FlxMath.minInt(b_s[2] ?? b_s[3] ?? pos, b_s[3] ?? b_s[2] ?? pos);
					case 2:
						pos = b_s[1] ?? pos;
				} // lmao
			} // else pos = FlxMath.maxInt(FlxMath.maxInt(FlxMath.maxInt(b_s[0] ?? pos, b_s[1] ?? pos), b_s[2] ?? pos), b_s[3] ?? pos);
			c = nextChar(); --pos;
			// trace(b_s[0].hex(8), b_s[1].hex(8), b_s[2].hex(8), b_s[3].hex(8), pos.hex(8), bracketMode, String.fromCharCode(c));
			
			if (bracketMode == 2) {
				prepareSkipMode = skipMode = false; ++pos; comma = true;
				#if debug trace('skipMode deactivated at $pos, $field'); #end
				skipDone = true;
			}
			
			if (pos > str.length) {
				prepareSkipMode = skipMode = false;
			} // emergency stop

			if (skipDone) return [];
			return parseRec(); // Recursive call instead of continue
		}

		switch (c) {
			case ' '.code, '\r'.code, '\n'.code, '\t'.code:
			// loop
			case '{'.code:
					obj[++objLayer] = {};
					field = null;
					comma = null;
					while (true) {
						showProgress();
						c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							// loop
							case '}'.code:
								if (field != null || comma == false)
									invalidChar();
								comma = null;
								return obj[objLayer--];
							case ':'.code:
								if (field == null)
									invalidChar();
								Reflect.setField(obj[objLayer], field, parseRec());
								field = null;
								comma = true;
							case ','.code:
								if (comma) comma = false else invalidChar();
							case '"'.code:
								if (field != null || comma) invalidChar();
								field = parseString();
								#if debug if (!skipMode) trace('field: $field'); #end
								if (skipChart && field == "notes") prepareSkipMode = true;
							default:
								invalidChar();
						}
					}
				case '['.code:
					if (prepareSkipMode) {
						var chrode:Int = 0;
						
						do {
							chrode = nextChar();
							if (chrode == ']'.code) {
								if (comma == false) invalidChar();
								comma = null; prepareSkipMode = false;
								return [];
							}
						} while (chrode == ' '.code || chrode == '\r'.code || chrode == '\n'.code || chrode == '\t'.code);
						
						skipMode = true;
						#if debug trace('skipMode activated at $pos'); #end
						continue;
					}
					arr[++arrLayer] = [];
					comma = null;
					while (true) {
						showProgress();
						c = nextChar();
						switch (c) {
							case ' '.code, '\r'.code, '\n'.code, '\t'.code:
							// loop
							case ']'.code:
								if (comma == false) invalidChar();
								comma = null;
								return arr[arrLayer--];
							case ','.code:
								if (comma) comma = false else invalidChar();
							default:
								arr[arrLayer].push(parseRec());
								comma = true;
						}
					}
				case '"'.code:
					return parseString();
				case 't'.code:
					pos += 3; // "rue"
					if (str.substr(pos - 3, 4) != "true")
						invalidChar();
					return true;
				case 'f'.code:
					pos += 4; // "alse"
					if (str.substr(pos - 4, 5) != "false")
						invalidChar();
					return false;
				case 'n'.code:
					pos += 3; // "ull"
					if (str.substr(pos - 3, 4) != "null")
						invalidChar();
					return null;
				default:
					if (c >= '0'.code && c <= '9'.code || c == '-'.code) {
						pos--;
						return parseNumber();
					}
					invalidChar();
			}
		return null; // This should never be reached, but needed for compilation
	}

	function parseString():String {
		var start = pos;
		var buf = new StringBuf();
		while (true) {
			var c = nextChar();
			switch (c) {
				case '"'.code:
					return buf.toString();
				case '\\'.code:
					buf.addSub(str, start, pos - start - 1);
					c = nextChar();
					switch (c) {
						case 'r'.code: buf.addChar('\r'.code);
						case 'n'.code: buf.addChar('\n'.code);
						case 't'.code: buf.addChar('\t'.code);
						case '\\'.code | '"'.code | '/'.code: buf.addChar(c);
						case 'u'.code:
							var uc = Std.parseInt('0x' + str.substr(pos, 4));
							pos += 4;
							if (uc <= 0x7F)
								buf.addChar(uc);
							else if (uc <= 0x7FF) {
								buf.addChar(0xC0 | (uc >> 6));
								buf.addChar(0x80 | (uc & 63));
							} else {
								buf.addChar(0xE0 | (uc >> 12));
								buf.addChar(0x80 | ((uc >> 6) & 63));
								buf.addChar(0x80 | (uc & 63));
							}
						default:
							throw 'Invalid escape sequence \\' + String.fromCharCode(c) + ' at position $pos';
					}
					start = pos;
				default:
					if (StringTools.isEof(c))
						throw 'Unclosed string at position $start';
			}
		}
	}

	function parseNumber():Float {
		var start = pos;
		var minus = false;
		var digit = false;
		if (c == '-'.code) {
			minus = true;
			c = nextChar();
		}
		if (c == '0'.code) {
			digit = true;
			c = nextChar();
		} else if (c >= '1'.code && c <= '9'.code) {
			digit = true;
			do c = nextChar() while (c >= '0'.code && c <= '9'.code);
		} else
			invalidChar();
		if (c == '.'.code) {
			digit = true;
			do c = nextChar() while (c >= '0'.code && c <= '9'.code);
		}
		if (c == 'e'.code || c == 'E'.code) {
			c = nextChar();
			if (c == '-'.code || c == '+'.code)
				c = nextChar();
			if (c < '0'.code || c > '9'.code)
				invalidChar();
			do c = nextChar() while (c >= '0'.code && c <= '9'.code);
		}
		pos--;
		if (!digit)
			invalidChar();
		return Std.parseFloat(str.substr(start, pos - start));
	}

	function nextChar():Int {
		return StringTools.fastCodeAt(str, pos++);
	}

	function invalidChar() {
		pos--; // rewind
		var end = Math.min(pos + 20, str.length);
		var start = Math.max(0, pos - 20);
		var excerpt = str.substr(start, end - start);
		throw 'Invalid char ' + String.fromCharCode(c) + ' at position $pos in \'$excerpt\'';
	}

	function showProgress() {
		#if sys
		if (log && pos % 10000 == 0) {
			var progress = Math.floor((pos / str.length) * 100);
			Sys.stdout().writeString('\x1b[0G$progress% ($pos/${str.length})');
		}
		#end
	}
}
