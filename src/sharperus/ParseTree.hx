package sharperus;

import sharperus.Token;

typedef Module = {
	var declarations:Array<Declaration>;
	var eof:Token;
}

enum Declaration {
	DGlobal(v:VarDecl);
	DConst(c:ConstDecl);
	DFunction(f:FunctionDecl);
	DClass(c:ClassDecl);
}

typedef ClassDecl = {
	var classKeyword:Token;
	var name:Token;
	var generic:Null<{
		var lt:Token;
		var params:Separated<Token>;
		var gt:Token;
	}>;
	var extend:Null<{keyword:Token, path:TypePath}>;
	var implement:Null<{keyword:Token, paths:Separated<DotPath>}>;
	var members:Array<ClassMember>;
	var end:BodyEnd;
}

typedef TypePath = {
	var dotPath:DotPath;
	var params:Null<TypeParams>;
}

typedef TypeParams = {
	var lt:Token;
	var types:Separated<SyntaxType>;
	var gt:Token;
}

typedef DotPath = Separated<Token>;

enum ClassMember {
	CField(v:VarDecl);
	CGlobal(g:VarDecl);
	CConst(c:ConstDecl);
	CFunction(f:FunctionDecl);
	CMethod(f:MethodDecl);
	CCtor(f:CtorDecl);
}

typedef ConstDecl = {
	var keyword:Token;
	var name:Token;
	var def:VarDeclDef;
}

typedef VarDecl = {
	var kind:VarDeclKind;
	var name:Token;
	var def:VarDeclDef;
}

typedef VarDeclKind = {
	var keyword:Token;
	var kind:VarDeclKindVariant;
}

enum VarDeclKindVariant {
	VKGlobal;
	VKLocal;
	VKField;
}

enum VarDeclDef {
	VDNormal(hint:Null<TypeHint>, init:Null<{equals:Token, expr:Expr}>);
	VDInferred(colonEquals:Token, expr:Expr);
}

enum Expr {
	EIdent(ident:Token);
	ELiteral(l:Literal);
	EArrayDecl(d:ArrayDecl);
	EUnop(op:Unop, e:Expr);
	EBinop(left:Expr, op:Binop, right:Expr);
	ENew(e:NewExpr);
	EMember(left:Expr, dot:Token, name:Token);
}

typedef NewExpr = {
	var newKeyword:Token;
	var typePath:TypePath;
	var callParams:Null<CallParams>;
}

typedef CallParams = {
	var openParen:Token;
	var params:Null<Separated<Expr>>;
	var closeParen:Token;
}

enum Unop {
	UPlus(t:Token);
	UMinus(t:Token);
	UCompl(t:Token);
	UNot(t:Token);
}

enum Binop {
	OpMul(t:Token);
	OpDiv(t:Token);
	OpMod(t:Token);
	OpShl(t:Token);
	OpShr(t:Token);
	OpAdd(t:Token);
	OpSub(t:Token);
	OpBitAnd(t:Token);
	OpBitXor(t:Token);
	OpBitOr(t:Token);
	OpEq(t:Token);
	OpLt(t:Token);
	OpLte(t:Token);
	OpGt(t:Token);
	OpGte(t:Token);
	OpNeq(t:Token);
	OpAnd(t:Token);
	OpOr(t:Token);
}

typedef ArrayDecl = {
	var openBracket:Token;
	var elems:Null<Separated<Expr>>;
	var closeBracket:Token;
}

enum Literal {
	LDecInt(t:Token);
	LHexInt(t:Token);
	LBool(t:Token);
	LFloat(t:Token);
	LString(t:Token);
	LChar(t:Token);
}

enum TypeHint {
	TShortBool(question:Token);
	TShortInt(percent:Token);
	TShortFloat(hash:Token);
	TShortString(dollar:Token);
	TSyntaxType(colon:Token, type:SyntaxType);
}

enum SyntaxType {
	TArray(elementType:SyntaxType, openBracket:Token, closeBracket:Token);
	TPath(path:TypePath);
}

typedef FunctionDecl = {
	var functionKeyword:Token;
	var name:Token;
	var returnType:Null<TypeHint>;
	var openParen:Token;
	var parameters:Null<Separated<FunctionDeclParam>>;
	var closeParen:Token;
	var body:Array<Statement>;
	var end:BodyEnd;
}

typedef FunctionDeclParam = {
	var name:Token;
	var def:VarDeclDef;
}

typedef MethodDecl = {
	var methodKeyword:Token;
	var name:Token;
	var returnType:Null<TypeHint>;
	var openParen:Token;
	var parameters:Null<Separated<FunctionDeclParam>>;
	var closeParen:Token;
	var propertyKeyword:Null<Token>;
	var body:Array<Statement>;
	var end:BodyEnd;
}

typedef CtorDecl = {
	var methodKeyword:Token;
	var newKeyword:Token;
	var openParen:Token;
	var parameters:Null<Separated<FunctionDeclParam>>;
	var closeParen:Token;
	var body:Array<Statement>;
	var end:BodyEnd;
}

typedef BodyEnd = {
	var endKeyword:Token;
	var kindKeyword:Null<Token>;
}

typedef Separated<T> = {
	var first:T;
	var rest:Array<{sep:Token, element:T}>;
}

typedef Statement = {
	var kind:StatementKind;
	var semicolon:Null<Token>;
}

enum StatementKind {
	SExpr(e:Expr);
	SIf(s:IfStatement);
	SWhile(w:WhileStatement);
	SRepeat(w:RepeatStatement);
	SLocal(v:VarDecl);
	SExit(keyword:Token);
	SContinue(keyword:Token);
	SAssign(left:Expr, equals:Token, right:Expr);
}

typedef IfStatement = {
	var ifKeyword:Token;
	var condition:Expr;
	var thenToken:Null<Token>;
	var thenBody:Array<Statement>;
	var next:IfNext;
}

typedef ElseIfStatement = {
	var keyword:ElseIfKeyword;
	var condition:Expr;
	var thenToken:Null<Token>;
	var thenBody:Array<Statement>;
	var next:IfNext;
}

typedef ElseStatement = {
	var keyword:Token;
	var body:Array<Statement>;
	var end:IfEnd;
}

enum ElseIfKeyword {
	EISingle(keyword:Token);
	EISplit(elseKeyword:Token, ifKeyword:Token);
}

enum IfNext {
	INEnd(end:IfEnd);
	INElse(stmt:ElseStatement);
	INElseIf(stmt:ElseIfStatement);
}

enum IfEnd {
	IEEndIf(keyword:Token);
	IEEnd(end:BodyEnd);
}

typedef WhileStatement = {
	var whileKeyword:Token;
	var condition:Expr;
	var body:Array<Statement>;
	var end:WhileEnd;
}

enum WhileEnd {
	WEWend(keyword:Token);
	WEEnd(end:BodyEnd);
}

typedef RepeatStatement = {
	var repeatKeyword:Token;
	var body:Array<Statement>;
	var kind:RepeatKind;
}

enum RepeatKind {
	RForever(keyword:Token);
	RUntil(keyword:Token, condition:Expr);
}