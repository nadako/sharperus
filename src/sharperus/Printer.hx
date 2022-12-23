package sharperus;

import sharperus.Token;
import sharperus.ParseTree;

/** prints back parse tree so we can make sure we parsed everything absolutely correctly **/
class Printer extends PrinterBase {
	public static function print(module:Module) {
		var printer = new Printer();
		printer.printModule(module);
		return printer.toString();
	}

	function printModule(file:Module) {
		for (decl in file.declarations)
			printDeclaration(decl);
		printTrivia(file.eof.leadTrivia);
	}

	function printDeclaration(decl:Declaration) {
		switch (decl) {
			case DStrict(keyword):
				printKeyword("Strict", keyword);
			case DImport(keyword, path):
				printKeyword("Import", keyword);
				printDotPath(path);
			case DGlobal(varDecl):
				printVarDecl(varDecl);
			case DConst(constDecl):
				printConstDecl(constDecl);
			case DFunction(funDecl):
				printFunctionDecl(funDecl);
			case DClass(classDecl):
				printClassDecl(classDecl);
		}
	}

	function printClassDecl(classDecl:ClassDecl) {
		printKeyword("Class", classDecl.classKeyword);
		printIdent(classDecl.name);
		if (classDecl.generic != null) printClassGeneric(classDecl.generic);
		if (classDecl.extend != null) printClassExtend(classDecl.extend);
		if (classDecl.implement != null) printClassImplement(classDecl.implement);
		for (member in classDecl.members) {
			switch (member) {
				case CField(v) | CGlobal(v): printVarDecl(v);
				case CConst(c): printConstDecl(c);
				case CFunction(f): printFunctionDecl(f);
				case CMethod(f): printMethodDecl(f);
				case CCtor(f): printCtorDecl(f);
			}
		}
		printEnd(classDecl.end, "Class");
	}

	function printClassGeneric(generic:{lt:Token, params:Separated<Token>, gt:Token}) {
		printTextWithTrivia("<", generic.lt);
		printSeparated(generic.params, printIdent, printComma);
		printTextWithTrivia(">", generic.gt);
	}

	function printClassExtend(extend:{keyword:Token, path:TypePath}) {
		printKeyword("Extends", extend.keyword);
		printTypePath(extend.path);
	}

	function printClassImplement(implement:{keyword:Token, paths:Separated<DotPath>}) {
		printKeyword("Implements", implement.keyword);
		printSeparated(implement.paths, printDotPath, printComma);
	}

	function printConstDecl(c:ConstDecl) {
		printKeyword("Const", c.keyword);
		printIdent(c.name);
		printVarDef(c.def);
	}

	function printFunctionDecl(funDecl:FunctionDecl) {
		printKeyword("Function", funDecl.functionKeyword);
		printIdent(funDecl.name);
		if (funDecl.returnType != null) printTypeHint(funDecl.returnType);
		printOpenParen(funDecl.openParen);
		if (funDecl.parameters != null) printSeparated(funDecl.parameters, p -> {
			printIdent(p.name);
			printVarDef(p.def);
		}, printComma);
		printCloseParen(funDecl.closeParen);
		printStatements(funDecl.body);
		printEnd(funDecl.end, "Function");
	}

	function printEnd(end:BodyEnd, kind:String) {
		printKeyword("End", end.endKeyword);
		if (end.kindKeyword != null) printKeyword(kind, end.kindKeyword);
	}

	function printMethodDecl(methodDecl:MethodDecl) {
		printKeyword("Method", methodDecl.methodKeyword);
		printIdent(methodDecl.name);
		if (methodDecl.returnType != null) printTypeHint(methodDecl.returnType);
		printOpenParen(methodDecl.openParen);
		if (methodDecl.parameters != null) printSeparated(methodDecl.parameters, p -> {
			printIdent(p.name);
			printVarDef(p.def);
		}, printComma);
		printCloseParen(methodDecl.closeParen);
		printStatements(methodDecl.body);
		printEnd(methodDecl.end, "Method");
	}

	function printCtorDecl(methodDecl:CtorDecl) {
		printKeyword("Method", methodDecl.methodKeyword);
		printKeyword("New", methodDecl.newKeyword);
		printOpenParen(methodDecl.openParen);
		if (methodDecl.parameters != null) printSeparated(methodDecl.parameters, p -> {
			printIdent(p.name);
			printVarDef(p.def);
		}, printComma);
		printCloseParen(methodDecl.closeParen);
		printStatements(methodDecl.body);
		printEnd(methodDecl.end, "Method");
	}

	function printStatements(statements:Array<Statement>) {
		for (stmt in statements) {
			printStatement(stmt.kind);
			if (stmt.semicolon != null) printSemicolon(stmt.semicolon);
		}
	}

	function printStatement(s:StatementKind) {
		switch (s) {
			case SExpr(e):
				printExpr(e);
			case SIf(i):
				printKeyword("If", i.ifKeyword);
				printExpr(i.condition);
				if (i.thenToken != null) printKeyword("Then", i.thenToken);
				printStatements(i.thenBody);
				printIfNext(i.next);
			case SWhile(i):
				printKeyword("While", i.whileKeyword);
				printExpr(i.condition);
				printStatements(i.body);
				switch (i.end) {
					case WEWend(keyword): printKeyword("Wend", keyword);
					case WEEnd(end): printEnd(end, "While");
				}
			case SRepeat(i):
				printKeyword("Repeat", i.repeatKeyword);
				printStatements(i.body);
				switch (i.kind) {
					case RForever(keyword):
						printKeyword("Forever", keyword);
					case RUntil(keyword, condition):
						printKeyword("Until", keyword);
						printExpr(condition);
				}
			case SLocal(v):
				printVarDecl(v);
			case SExit(k):
				printKeyword("Exit", k);
			case SContinue(k):
				printKeyword("Continue", k);
			case SAssign(left, equals, right):
				printExpr(left);
				printTextWithTrivia("=", equals);
				printExpr(right);
			case SReturn(keyword, e):
				printKeyword("Return", keyword);
				if (e != null) printExpr(e);
		}
	}

	function printIfNext(next:IfNext) {
		switch (next) {
			case INEnd(end):
				printIfEnd(end);
			case INElse(e):
				printKeyword("Else", e.keyword);
				printStatements(e.body);
				printIfEnd(e.end);
			case INElseIf(e):
				switch (e.keyword) {
					case EISingle(keyword):
						printKeyword("ElseIf", keyword);
					case EISplit(elseKeyword, ifKeyword):
						printKeyword("Else", elseKeyword);
						printKeyword("If", ifKeyword);
				}
				printExpr(e.condition);
				if (e.thenToken != null) printKeyword("Then", e.thenToken);
				printStatements(e.thenBody);
				printIfNext(e.next);
		}
	}

	function printIfEnd(end:IfEnd) {
		switch (end) {
			case IEEndIf(keyword): printKeyword("EndIf", keyword);
			case IEEnd(end): printEnd(end, "If");
		}
	}

	function printVarDecl(v:VarDecl) {
		switch (v.kind.kind) {
			case VKGlobal: printKeyword("Global", v.kind.keyword);
			case VKLocal: printKeyword("Local", v.kind.keyword);
			case VKField: printKeyword("Field", v.kind.keyword);
		}
		printIdent(v.name);
		printVarDef(v.def);
	}

	function printVarDef(def:VarDeclDef) {
		switch (def) {
			case VDNormal(hint, init):
				if (hint != null) {
					printTypeHint(hint);
				}
				if (init != null) {
					printTextWithTrivia("=", init.equals);
					printExpr(init.expr);
				}
			case VDInferred(colonEquals, expr):
				printTextWithTrivia(":=", colonEquals);
				printExpr(expr);
		}
	}

	function printTypeHint(hint:TypeHint) {
		switch (hint) {
			case TShortBool(question):
				printTextWithTrivia("?", question);
			case TShortInt(percent):
				printTextWithTrivia("%", percent);
			case TShortFloat(hash):
				printTextWithTrivia("#", hash);
			case TShortString(dollar):
				printTextWithTrivia("$", dollar);
			case TSyntaxType(colon, type):
				printColon(colon);
				printSyntaxType(type);
		}
	}

	function printSyntaxType(type:SyntaxType) {
		switch (type) {
			case TPath(tp):
				printTypePath(tp);
			case TArray(elementType, openBracket, closeBracket):
				printSyntaxType(elementType);
				printTextWithTrivia("[", openBracket);
				printTextWithTrivia("]", closeBracket);
		}
	}

	function printTypePath(tp:TypePath) {
		printDotPath(tp.dotPath);
		var params = tp.params;
		if (params != null) {
			printTextWithTrivia("<", params.lt);
			printSeparated(params.types, printSyntaxType, printComma);
			printTextWithTrivia(">", params.gt);
		}
	}

	function printExpr(e:Expr) {
		switch (e) {
			case EIdent(ident):
				printIdent(ident);
			case ELiteral(LDecInt(t) | LHexInt(t) | LBool(t) | LFloat(t) | LString(t) | LChar(t)):
				printTextWithTrivia(t.text, t);
			case EArrayDecl(d):
				printTextWithTrivia("[", d.openBracket);
				if (d.elems != null) printSeparated(d.elems, printExpr, printComma);
				printTextWithTrivia("]", d.closeBracket);
			case EUnop(op, e):
				printUnop(op, e);
			case EBinop(left, op, right):
				printExpr(left);
				printBinop(op);
				printExpr(right);
			case ENew(n):
				printKeyword("New", n.newKeyword);
				printTypePath(n.typePath);
				if (n.callParams != null) printCallParams(n.callParams);
			case EMember(e, dot, name):
				printExpr(e);
				printDot(dot);
				printIdent(name);
			case ECall(e, params):
				printExpr(e);
				printCallParams(params);
			case EIndex(e, ob, i, cb):
				printExpr(e);
				printTextWithTrivia("[", ob);
				switch (i) {
					case Single(e):
						printExpr(e);
					case Slice(start, twoDots, end):
						if (start != null) printExpr(start);
						printTextWithTrivia("..", twoDots);
						if (end != null) printExpr(end);
				}
				printTextWithTrivia("]", cb);
		}
	}

	function printCallParams(params:CallParams) {
		printTextWithTrivia("(", params.openParen);
		if (params.params != null) printSeparated(params.params, printExpr, printComma);
		printTextWithTrivia(")", params.closeParen);
	}

	function printBinop(op:Binop) {
		switch (op) {
			case OpMul(t): printTextWithTrivia("*", t);
			case OpDiv(t): printTextWithTrivia("/", t);
			case OpMod(t): printTextWithTrivia("Mod", t);
			case OpShl(t): printTextWithTrivia("Shl", t);
			case OpShr(t): printTextWithTrivia("Shr", t);
			case OpAdd(t): printTextWithTrivia("+", t);
			case OpSub(t): printTextWithTrivia("-", t);
			case OpBitAnd(t): printTextWithTrivia("&", t);
			case OpBitXor(t): printTextWithTrivia("~", t);
			case OpBitOr(t): printTextWithTrivia("|", t);
			case OpEq(t): printTextWithTrivia("=", t);
			case OpLt(t): printTextWithTrivia("<", t);
			case OpLte(t): printTextWithTrivia("<=", t);
			case OpGt(t): printTextWithTrivia(">", t);
			case OpGte(t): printTextWithTrivia(">=", t);
			case OpNeq(t): printTextWithTrivia("<>", t);
			case OpAnd(t): printTextWithTrivia("And", t);
			case OpOr(t): printTextWithTrivia("Or", t);
		}
	}

	function printUnop(op:Unop, e:Expr) {
		switch (op) {
			case UPlus(t):
				printTextWithTrivia("+", t);
			case UMinus(t):
				printTextWithTrivia("-", t);
			case UCompl(t):
				printTextWithTrivia("~", t);
			case UNot(t):
				printKeyword("Not", t);
		}
		printExpr(e);
	}

	function printKeyword(kwd:String, token:Token) {
		if (kwd.toLowerCase() != token.text.toLowerCase()) buf.add('{WRONG KEYWORD: $kwd}');
		printIdent(token);
	}
}