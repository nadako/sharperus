package sharperus;

import haxe.Exception;
import sharperus.ParseTree;
import sharperus.Token.Trivia;
import sharperus.TypedTree;

class GenCs extends PrinterBase {
	public static function print(module:TModule):String {
		var p = new GenCs();
		p.printModule(module);
		return p.toString();
	}

	function printModule(module:TModule) {
		for (d in module.declarations) {
			switch (d) {
				case TDStrict(syntax):
					syntax.removeTrailingNewline();
					printTextWithTrivia("", syntax); // TODO: strip trailing newline
				case TDGlobal(g):
					throw new Exception("Globals should be packed into a static class");
				case TDClass(c):
					printClass(c);
			}
		}
	}

	function printClass(c:TClassDecl) {
		printTextWithTrivia("class", c.syntax.classKeyword);
		printTextWithTrivia(c.name + " {", c.syntax.name);
		printEnd("}", c.syntax.end);
	}

	function printEnd(text:String, c:BodyEnd) {
		printTextWithTrivia(text, c.endKeyword);
		if (c.kindKeyword != null) printTextWithTrivia("", c.kindKeyword);
	}

	override function printTriviaItem(item:Trivia) {
		var text = item.text;
		switch (item.kind) {
			case TrLineComment:
				text = "//" + text.substring(1); // replace ' with //
			case _:
		}
		buf.add(text);
	}
}
