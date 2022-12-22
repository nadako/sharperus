package sharperus;

class TypedTree {
	public function new() {}
}

typedef TModule = {
	var declarations:Array<TDecl>;
}

typedef TDecl = {
	var name:String;
	var kind:TDeclKind;
}

enum TDeclKind {
	TDGlobal(g:TGlobalVar);
}

typedef TGlobalVar = {
	var type:TType;
	var init:Null<TExpr>;
}

enum TType {
	TVoid;
	TBool;
	TInt;
	TFloat;
	TString;
}

typedef TExpr = {
	var type:TType;
	var kind:TExprKind;
	var expectedType:TType;
}

enum TExprKind {
	TELiteral(l:TLiteral);
}

enum TLiteral {
	TLBool(b:Bool);
}