package sharperus;

import sharperus.Token;
using StringTools;

class Scanner {
	static final keywords = [
		for (keyword in Type.allEnums(Keyword))
			keyword.getName().toLowerCase().substring(3) => keyword
	];

	public var pos(default, null):Int;

	final text:String;
	final end:Int;

	var tokenStartPos:Int;
	var leadTrivia:Array<Trivia>;
	var lastToken:Null<Token>;

	public function new(text:String) {
		this.text = text;
		end = text.length;
		pos = tokenStartPos = 0;
		leadTrivia = [];
	}

	public function advance():PeekToken {
		if (lastToken != null) {
			return lastToken;
		}
		lastToken = scan();
		// @:nullSafety(Off) trace(lastToken);
		return lastToken;
	}

	public function consume():Token {
		var consumedToken = lastToken;
		if (consumedToken == null) throw new haxe.Exception("No token to consume");
		lastToken = null;
		return consumedToken;
	}

	function scan():Token {
		while (true) {
			leadTrivia = scanTrivia(false);

			tokenStartPos = pos;
			if (pos >= end) return mk(TkEof);

			var ch = text.fastCodeAt(pos);
			switch (ch) {
				case ":".code:
					pos++;
					ch = text.fastCodeAt(pos);
					if (ch == "=".code) {
						pos++;
						return mk(TkColonEquals);
					} else {
						return mk(TkColon);
					}

				case ";".code:
					pos++;
					return mk(TkSemicolon);

				case "*".code:
					pos++;
					if (pos < end) {
						switch (text.fastCodeAt(pos)) {
							case "=".code:
								pos++;
								return mk(TkAsteriskEquals);
							case _:
								return mk(TkAsterisk);
						}
					} else {
						return mk(TkAsterisk);
					}

				case "/".code:
					pos++;
					if (pos < end) {
						switch (text.fastCodeAt(pos)) {
							case "=".code:
								pos++;
								return mk(TkSlashEquals);
							case _:
								return mk(TkSlash);
						}
					} else {
						return mk(TkSlash);
					}

				case "+".code:
					pos++;
					if (pos < end) {
						switch (text.fastCodeAt(pos)) {
							case "=".code:
								pos++;
								return mk(TkPlusEquals);
							case _:
								return mk(TkPlus);
						}
					} else {
						return mk(TkPlus);
					}

				case "-".code:
					pos++;
					if (pos < end) {
						switch (text.fastCodeAt(pos)) {
							case "=".code:
								pos++;
								return mk(TkMinusEquals);
							case _:
								return mk(TkMinus);
						}
					} else {
						return mk(TkMinus);
					}


				case "~".code:
					pos++;
					if (pos < end) {
						switch (text.fastCodeAt(pos)) {
							case "=".code:
								pos++;
								return mk(TkTildeEquals);
							case _:
								return mk(TkTilde);
						}
					} else {
						return mk(TkTilde);
					}

				case "\"".code:
					pos++;
					scanString(ch);
					return mk(TkString);

				case "`".code:
					pos++;
					if (pos >= end) {
						throw "Unterminated character at " + tokenStartPos;
					}
					ch = text.fastCodeAt(pos);
					if (ch == "~".code) {
						pos++;
						scanEscapeSequence(pos - 1);
					} else {
						pos++;
					}

					if (pos >= end || text.fastCodeAt(pos) != "`".code) {
						throw "Unterminated character at " + tokenStartPos;
					}
					pos++;
					return mk(TkChar);

				case ".".code:
					pos++;
					if (pos < end) {
						ch = text.fastCodeAt(pos);
						if (isDigit(ch)) {
							pos++;
							scanDigits(); // TODO: does cerberus support scientific notation?
							return mk(TkFloat);
						} else {
							return mk(TkDot);
						}

					} else {
						return mk(TkDot);
					}

				case "<".code:
					pos++;
					return mk(TkLt);

				case ">".code:
					pos++;
					return mk(TkGt);

				case "0".code:
					pos++;
					if (pos < end && text.fastCodeAt(pos) == ".".code) {
						pos++;
						scanDigits();
						return mk(TkFloat);
					} else {
						return mk(TkDecInteger);
					}

				case "1".code | "2".code | "3".code | "4".code | "5".code | "6".code | "7".code | "8".code | "9".code:
					pos++;
					scanDigits();
					if (pos < end && text.fastCodeAt(pos) == ".".code) {
						pos++;
						scanDigits();
						return mk(TkFloat);
					} else {
						return mk(TkDecInteger);
					}

				case "$".code:
					pos++;
					if (pos < end) {
						ch = text.fastCodeAt(pos);
						if (isHexDigit(ch)) {
							pos++;
							scanHexDigits();
						}
						return mk(TkHexInteger);
					}
					return mk(TkDollar);

				case "=".code:
					pos++;
					return mk(TkEquals);

				case "?".code:
					pos++;
					return mk(TkQuestion);

				case "(".code:
					pos++;
					return mk(TkParenOpen);

				case ")".code:
					pos++;
					return mk(TkParenClose);

				case "[".code:
					pos++;
					return mk(TkBracketOpen);

				case "]".code:
					pos++;
					return mk(TkBracketClose);

				case ",".code:
					pos++;
					return mk(TkComma);

				case "_".code:
					// single underscore must be followed by an alphabetic
					pos++;
					ch = text.fastCodeAt(pos);
					if (isAlphabetic(ch)) {
						pos++;
						while (pos < end) {
							ch = text.fastCodeAt(pos);
							if (!isIdentPart(ch))
								break;
							pos++;
						}
						return mk(TkIdent);
					} else {
						return mk(TkUnknown);
					}

				case _ if (isAlphabetic(ch)):
					pos++;
					while (pos < end) {
						ch = text.fastCodeAt(pos);
						if (!isIdentPart(ch))
							break;
						pos++;
					}
					return mkIdent();

				case _:
					pos++;
					return mk(TkUnknown);
			}
		}
	}

	function scanString(delimeter:Int) {
		while (true) {
			if (pos >= end) {
				throw "Unterminated string at " + tokenStartPos;
			}
			var ch = text.fastCodeAt(pos);
			if (ch == delimeter) {
				pos++;
				break;
			} else if (ch == "~".code) {
				pos++;
				scanEscapeSequence(pos - 1);
			} else {
				pos++;
			}
		}
	}

	function scanEscapeSequence(start:Int) {
		if (pos >= end) {
			throw "Unterminated escape sequence at " + start;
		}
		var ch = text.fastCodeAt(pos);
		pos++;
		return switch (ch) {
			case "q".code:
			case "g".code:
			case "n".code:
			case "r".code:
			case "t".code:
			case "z".code:
			case "~".code:
			case "u".code:
				for (_ in 0...4) {
					if (pos >= end) {
						throw "Unterminated unicode character sequence at " + start;
					}
					ch = text.fastCodeAt(pos);
					if (!isHexDigit(ch)) {
						throw "Invalid unicode character sequence at " + start;
					}
					pos++;
				}
			default:
				throw "Invalid escape sequence at " + start;
		}
	}

	function scanTrivia(breakOnNewLine:Bool):Array<Trivia> {
		var trivia = [];
		while (pos < end) {
			tokenStartPos = pos;

			var ch = text.fastCodeAt(pos);
			switch ch {
				case "\r".code:
					pos++;
					if (text.fastCodeAt(pos) == "\n".code)
						pos++;
					trivia.push(mkTrivia(TrNewline));
					if (breakOnNewLine)
						break;

				case "\n".code:
					pos++;
					trivia.push(mkTrivia(TrNewline));
					if (breakOnNewLine)
						break;

				case " ".code | "\t".code:
					pos++;
					while (pos < end) {
						ch = text.fastCodeAt(pos);
						if (ch == " ".code || ch == "\t".code) {
							pos++;
						} else {
							break;
						}
					}
					trivia.push(mkTrivia(TrWhitespace));

				case "'".code:
					pos++;
					while (pos < end) {
						ch = text.fastCodeAt(pos);
						if (ch == "\r".code || ch == "\n".code)
							break;
						pos++;
					}
					trivia.push(mkTrivia(TrLineComment));

				case _:
					break;
			}
		}
		return trivia;
	}

	function mkTrivia(kind:TriviaKind):Trivia {
		return new Trivia(kind, text.substring(tokenStartPos, pos));
	}

	function mkIdent():Token {
		var potentialKeyword = text.substring(tokenStartPos, pos).toLowerCase();
		var keyword = keywords[potentialKeyword];
		return if (keyword != null) mk(TkKeyword(keyword)) else mk(TkIdent);
	}

	function mk(kind:TokenKind):Token {
		var text = text.substring(tokenStartPos, pos);
		return new Token(tokenStartPos, kind, text, leadTrivia, scanTrivia(true));
	}

	inline function scanDigits() {
		while (pos < end && isDigit(text.fastCodeAt(pos))) {
			pos++;
		}
	}

	inline function scanHexDigits() {
		while (pos < end && isHexDigit(text.fastCodeAt(pos))) {
			pos++;
		}
	}

	inline function isDigit(ch) {
		return ch >= "0".code && ch <= "9".code;
	}

	inline function isHexDigit(ch) {
		return (ch >= "0".code && ch <= "9".code) || (ch >= "a".code && ch <= "f".code) || (ch >= "A".code && ch <= "F".code);
	}

	inline function isAlphabetic(ch) {
		return (ch >= "a".code && ch <= "z".code) || (ch >= "A".code && ch <= "Z".code);
	}

	inline function isIdentPart(ch) {
		return ch == "_".code || isDigit(ch) || isAlphabetic(ch);
	}
}