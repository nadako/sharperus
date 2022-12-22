package sharperus;

class Token {
	public final pos:Int;
	public final kind:TokenKind;
	public final text:String;
	public final leadTrivia:Array<Trivia>;
	public final trailTrivia:Array<Trivia>;

	public function new(pos, kind, text, leadTrivia, trailTrivia) {
		this.pos = pos;
		this.kind = kind;
		this.text = text;
		this.leadTrivia = leadTrivia;
		this.trailTrivia = trailTrivia;
	}

	public function toString() {
		return '${kind.getName()}(${haxe.Json.stringify(text)})';
	}
}

@:forward(kind, text, leadTrivia, trailTrivia)
abstract PeekToken(Token) from Token {}

enum TokenKind {
	TkKeyword(kwd:Keyword);
	TkIdent;
	TkLt;
	TkLtEquals;
	TkGt;
	TkGtEquals;
	TkLtGt;
	TkDot;
	TkComma;
	TkSemicolon;
	TkColon;
	TkColonEquals;
	TkEquals;
	TkPlus;
	TkPlusEquals;
	TkMinus;
	TkMinusEquals;
	TkAmpersand;
	TkAmpersandEquals;
	TkAsterisk;
	TkAsteriskEquals;
	TkSlashEquals;
	TkSlash;
	TkTilde;
	TkTildeEquals;
	TkPipe;
	TkPipeEquals;
	TkQuestion;
	TkPercent;
	TkHash;
	TkDollar;
	TkEof;
	TkParenOpen;
	TkParenClose;
	TkBracketOpen;
	TkBracketClose;
	TkDecInteger;
	TkHexInteger;
	TkFloat;
	TkString;
	TkChar;
	TkUnknown;
}

enum Keyword {
	KwdVoid;
	KwdStrict;
	KwdPublic;
	KwdPrivate;
	KwdProperty;
	KwdBool;
	KwdInt;
	KwdFloat;
	KwdString;
	KwdArray;
	KwdObject;
	KwdMod;
	KwdContinue;
	KwdExit;
	KwdImport;
	KwdInclude;
	KwdExtern;
	KwdNew;
	KwdSelf;
	KwdSuper;
	KwdTry;
	KwdCatch;
	KwdEachin;
	KwdTrue;
	KwdFalse;
	KwdNot;
	KwdExtends;
	KwdAbstract;
	KwdFinal;
	KwdSelect;
	KwdCase;
	KwdDefault;
	KwdConst;
	KwdEnumerate;
	KwdLocal;
	KwdGlobal;
	KwdField;
	KwdMethod;
	KwdFunction;
	KwdClass;
	KwdAnd;
	KwdOr;
	KwdShl;
	KwdShr;
	KwdEnd;
	KwdIf;
	KwdThen;
	KwdElse;
	KwdElseIf;
	KwdEndIf;
	KwdWhile;
	KwdWend;
	KwdRepeat;
	KwdUntil;
	KwdForever;
	KwdFor;
	KwdTo;
	KwdStep;
	KwdNext;
	KwdReturn;
	KwdModule;
	KwdInterface;
	KwdImplements;
	KwdInline;
	KwdThrow;
}

class Trivia {
	public final kind:TriviaKind;
	public final text:String;

	public function new(kind, text) {
		this.kind = kind;
		this.text = text;
	}

	public function toString() {
		return '${kind.getName()}(${haxe.Json.stringify(text)})';
	}
}

enum TriviaKind {
	TrWhitespace;
	TrNewline;
	TrLineComment;
}
