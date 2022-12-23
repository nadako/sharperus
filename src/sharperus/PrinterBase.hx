package sharperus;

import sharperus.Token;
import sharperus.ParseTree;

class PrinterBase {
	final buf:StringBuf;

	function new() {
		buf = new StringBuf();
	}

	function printSemicolon(token:Token) {
		printTextWithTrivia(";", token);
	}

	function printComma(token:Token) {
		printTextWithTrivia(",", token);
	}

	function printOpenParen(token:Token) {
		printTextWithTrivia("(", token);
	}

	function printCloseParen(token:Token) {
		printTextWithTrivia(")", token);
	}

	function printDotPath(p:DotPath) {
		printSeparated(p, printIdent, printDot);
	}

	inline function printIdent(token:Token) {
		printTextWithTrivia(token.text, token);
	}

	inline function printColon(s:Token) {
		printTextWithTrivia(":", s);
	}

	inline function printDot(s:Token) {
		printTextWithTrivia(".", s);
	}

	function printTextWithTrivia(text:String, triviaToken:Token) {
		printTrivia(triviaToken.leadTrivia);
		buf.add(text);
		printTrivia(triviaToken.trailTrivia);
	}

	function printTrivia(trivia:Array<Trivia>) {
		for (item in trivia) {
			printTriviaItem(item);
		}
	}

	function printTriviaItem(item:Trivia) {
		buf.add(item.text);
	}

	function printSeparated<T>(s:Separated<T>, f:T->Void, fsep:Token->Void) {
		f(s.first);
		for (v in s.rest) {
			fsep(v.sep);
			f(v.element);
		}
	}

	function toString() {
		return buf.toString();
	}
}