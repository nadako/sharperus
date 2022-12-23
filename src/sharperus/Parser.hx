package sharperus;

import haxe.Exception;
import sharperus.ParseTree;
import sharperus.Token;

class Parser {
	final scanner:Scanner;
	final path:String;

	public function new(scanner, path) {
		this.scanner = scanner;
		this.path = path;
	}

	public inline function parse() return parseModule();

	function parseModule():Module {
		return {
			declarations: parseSequence(parseDeclaration),
			eof: expectKind(TkEof),
		};
	}

	function parseDeclaration():Null<Declaration> {
		while (true) {
			var token = scanner.advance();
			switch (token.kind) {
				case TkKeyword(KwdGlobal):
					return DGlobal(parseVarDeclNext({keyword: scanner.consume(), kind: VKGlobal}));
				case TkKeyword(KwdConst):
					return DConst(parseConstDeclNext(scanner.consume()));
				case TkKeyword(KwdFunction):
					return DFunction(parseFunctionDeclNext(scanner.consume()));
				case TkKeyword(KwdClass):
					return DClass(parseClassDeclNext(scanner.consume()));
				case _:
					return null;
			}
		}
	}

	function parseClassDeclNext(classKeyword:Token):ClassDecl {
		return {
			classKeyword: classKeyword,
			name: expectKind(TkIdent),
			generic: switch (scanner.advance().kind) {
				case TkLt:
					{
						lt: scanner.consume(),
						params: parseCommaSeparated(expectKind.bind(TkIdent)),
						gt: expectKind(TkGt),
					}
				case _:
					null;
			},
			extend: switch (scanner.advance().kind) {
				case TkKeyword(KwdExtends):
					{
						keyword: scanner.consume(),
						path: parseTypePath()
					}
				case _:
					null;
			},
			implement: switch (scanner.advance().kind) {
				case TkKeyword(KwdImplements):
					{
						keyword: scanner.consume(),
						paths: parseCommaSeparated(parseDotPath)
					}
				case _:
					null;
			},
			members: parseSequence(parseClassMember),
			end: parseEnd(KwdClass),
		};
	}

	function parseClassMember():Null<ClassMember> {
		switch (scanner.advance().kind) {
			case TkKeyword(KwdField):
				return CField(parseVarDeclNext({keyword: scanner.consume(), kind: VKField}));
			case TkKeyword(KwdGlobal):
				return CGlobal(parseVarDeclNext({keyword: scanner.consume(), kind: VKGlobal}));
			case TkKeyword(KwdConst):
				return CConst(parseConstDeclNext(scanner.consume()));
			case TkKeyword(KwdFunction):
				return CFunction(parseFunctionDeclNext(scanner.consume()));
			case TkKeyword(KwdMethod):
				var methodKeyword = scanner.consume();
				switch (scanner.advance().kind) {
					case TkKeyword(KwdNew):
						return CCtor(parseCtorDeclNext(methodKeyword, scanner.consume()));
					case _:
						return CMethod(parseMethodDeclNext(methodKeyword));
				}
			case _:
				return null;
		}
	}

	function parseConstDeclNext(constKeyword:Token):ConstDecl {
		return {
			keyword: constKeyword,
			name: expectKind(TkIdent),
			def: parseVarDeclDef()
		};
	}

	function parseFunctionDeclNext(functionKeyword:Token):FunctionDecl {
		return {
			functionKeyword: functionKeyword,
			name: expectKind(TkIdent),
			returnType: parseOptionalTypeHint(),
			openParen: expectKind(TkParenOpen),
			parameters: parseFunctionDeclParams(),
			closeParen: expectKind(TkParenClose),
			body: parseStatements(),
			end: parseEnd(KwdFunction),
		};
	}

	function parseEnd(kindKwd:Keyword):BodyEnd {
		return parseEndNext(expectKeyword(KwdEnd), kindKwd);
	}

	function parseEndNext(endKeyword:Token, kindKwd:Keyword):BodyEnd {
		return {
			endKeyword: endKeyword,
			kindKeyword: switch (scanner.advanceSameLine().kind) {
				case TkKeyword(kwd) if (kwd == kindKwd):
					scanner.consume();
				case _:
					null;
			}
		};
	}

	function parseMethodDeclNext(methodKeyword:Token):MethodDecl {
		return {
			methodKeyword: methodKeyword,
			name: expectKind(TkIdent),
			returnType: parseOptionalTypeHint(),
			openParen: expectKind(TkParenOpen),
			parameters: parseFunctionDeclParams(),
			closeParen: expectKind(TkParenClose),
			propertyKeyword: expectOptional(t -> t.kind.match(TkKeyword(KwdProperty))),
			body: parseStatements(),
			end: parseEnd(KwdMethod),
		};
	}

	function parseCtorDeclNext(methodKeyword:Token, newKeyword:Token):CtorDecl {
		return {
			methodKeyword: methodKeyword,
			newKeyword: newKeyword,
			openParen: expectKind(TkParenOpen),
			parameters: parseFunctionDeclParams(),
			closeParen: expectKind(TkParenClose),
			body: parseStatements(),
			end: parseEnd(KwdMethod),
		};
	}

	function parseStatements():Array<Statement> {
		return parseSequence(parseOptionalStatement);
	}

	function parseOptionalStatement():Null<Statement> {
		var kind = switch (scanner.advance().kind) {
			case TkKeyword(KwdIf):
				SIf(parseIf(scanner.consume()));

			case TkKeyword(KwdWhile):
				SWhile(parseWhile(scanner.consume()));

			case TkKeyword(KwdRepeat):
				SRepeat(parseRepeat(scanner.consume()));

			case TkKeyword(KwdLocal):
				SLocal(parseVarDeclNext({keyword: scanner.consume(), kind: VKLocal}));

			case TkKeyword(KwdExit):
				SExit(scanner.consume());

			case TkKeyword(KwdContinue):
				SContinue(scanner.consume());

			case _:
				var expr = parseOptionalExpr();
				if (expr == null) return null;
				parseExpressionStatementNext(expr);
		};

		return {kind: kind, semicolon: parseOptionalSemicolon()};
	}

	function parseExpressionStatementNext(expr:Expr) {
		switch (scanner.advance().kind) {
			case TkEquals:
				return SAssign(expr, scanner.consume(), parseExpr());
			case _:
				return SExpr(expr);
		}
	}

	function parseIf(ifKeyword:Token):IfStatement {
		return {
			ifKeyword: ifKeyword,
			condition: parseExpr(),
			thenToken: expectOptional(t -> t.kind.match(TkKeyword(KwdThen))),
			thenBody: parseStatements(),
			next: parseIfNext()
		}
	}

	function parseIfNext():IfNext {
		var ifEnd = parseOptionalIfEnd();
		if (ifEnd != null) {
			return INEnd(ifEnd);
		} else {
			return parseElse();
		}
	}

	function parseOptionalIfEnd():Null<IfEnd> {
		return switch (scanner.advance().kind) {
			case TkKeyword(KwdEndIf):
				IEEndIf(scanner.consume());
			case TkKeyword(KwdEnd):
				IEEnd(parseEndNext(scanner.consume(), KwdIf));
			case _:
				null;
		}
	}

	function parseIfEnd():IfEnd {
		var end = parseOptionalIfEnd();
		if (end == null) throw new Exception("EndIf expected");
		return end;
	}

	function parseElse():IfNext {
		switch (scanner.advance().kind) {
			case TkKeyword(KwdElseIf):
				return INElseIf(parseElseIf(EISingle(scanner.consume())));
			case TkKeyword(KwdElse):
				var elseKeyword = scanner.consume();
				switch (scanner.advance().kind) {
					case TkKeyword(KwdIf):
						return INElseIf(parseElseIf(EISplit(elseKeyword, scanner.consume())));
					case _:
						return INElse({
							keyword: elseKeyword,
							body: parseStatements(),
							end: parseIfEnd()
						});
				}
			case t:
				throw new Exception("Unexpected token after if body: " + t);
		}
	}

	function parseElseIf(keyword:ElseIfKeyword):ElseIfStatement {
		return {
			keyword: keyword,
			condition: parseExpr(),
			thenToken: expectOptional(t -> t.kind.match(TkKeyword(KwdThen))),
			thenBody: parseStatements(),
			next: parseIfNext()
		};
	}

	function parseWhile(whileKeyword:Token):WhileStatement {
		return {
			whileKeyword: whileKeyword,
			condition: parseExpr(),
			body: parseStatements(),
			end: switch (scanner.advance().kind) {
				case TkKeyword(KwdWend):
					WEWend(scanner.consume());
				case _:
					WEEnd(parseEnd(KwdWhile));
			}
		}
	}

	function parseRepeat(repeatKeyword:Token):RepeatStatement {
		return {
			repeatKeyword: repeatKeyword,
			body: parseStatements(),
			kind: switch (scanner.advance().kind) {
				case TkKeyword(KwdForever):
					RForever(scanner.consume());
				case TkKeyword(KwdUntil):
					RUntil(scanner.consume(), parseExpr());
				case _:
					throw new Exception("Unexpected end of the Repeat statement");
			}
		}
	}

	function parseOptionalSemicolon():Null<Token> {
		return expectOptional(t -> t.kind == TkSemicolon);
	}

	function parseFunctionDeclParams():Null<Separated<FunctionDeclParam>> {
		var first = parseOptionalFunctionDeclParam();
		if (first == null) return null;
		return parseSeparatedNext(first, parseFunctionDeclParam, t -> t.kind == TkComma);
	}

	function parseOptionalFunctionDeclParam():Null<FunctionDeclParam> {
		return switch (scanner.advance().kind) {
			case TkIdent:
				{name: scanner.consume(), def: parseVarDeclDef()}
			case _:
				null;
		};
	}

	function parseFunctionDeclParam():FunctionDeclParam {
		var param = parseOptionalFunctionDeclParam();
		if (param == null) throw new Exception("Function parameter expected");
		return param;
	}

	function parseVarDeclNext(kind:VarDeclKind):VarDecl {
		return {
			kind: kind,
			name: expectKind(TkIdent),
			def: parseVarDeclDef()
		};
	}

	function parseVarDeclDef():VarDeclDef {
		var nextToken = scanner.advance();
		if (nextToken.kind == TkColonEquals) {
			return VDInferred(scanner.consume(), parseExpr());
		} else {
			var hint = parseOptionalTypeHint();
			var init = switch (scanner.advance().kind) {
				case TkEquals:
					{equals: scanner.consume(), expr: parseExpr()}
				case _:
					null;
			}
			return VDNormal(hint, init);
		}
	}

	function parseOptionalExpr():Null<Expr> {
		var token = scanner.advance();
		switch (token.kind) {
			case TkIdent:
				return parseExprIdent(scanner.consume());
			case TkKeyword(KwdTrue | KwdFalse):
				return parseExprNext(ELiteral(LBool(scanner.consume())));
			case TkDecInteger:
				return parseExprNext(ELiteral(LDecInt(scanner.consume())));
			case TkHexInteger:
				return parseExprNext(ELiteral(LHexInt(scanner.consume())));
			case TkFloat:
				return parseExprNext(ELiteral(LFloat(scanner.consume())));
			case TkString:
				return parseExprNext(ELiteral(LString(scanner.consume())));
			case TkChar:
				return parseExprNext(ELiteral(LChar(scanner.consume())));
			case TkBracketOpen:
				return parseExprNext(EArrayDecl(parseArrayDecl(scanner.consume())));
			case TkPlus:
				return parseExprNext(EUnop(UPlus(scanner.consume()), parseExpr()));
			case TkMinus:
				return parseExprNext(EUnop(UMinus(scanner.consume()), parseExpr()));
			case TkTilde:
				return parseExprNext(EUnop(UCompl(scanner.consume()), parseExpr()));
			case TkKeyword(KwdNot):
				return parseExprNext(EUnop(UNot(scanner.consume()), parseExpr()));
			case TkKeyword(KwdNew):
				return parseNewNext(scanner.consume());
			case _:
				return null;
		}
	}

	function parseNewNext(newToken:Token) {
		return parseExprNext(ENew({
			newKeyword: newToken,
			typePath: parseTypePath(),
			callParams: parseOptionalCallParams(),
		}));
	}

	function parseOptionalCallParams():Null<CallParams> {
		var openParen = expectOptional(t -> t.kind == TkParenOpen);
		if (openParen == null) {
			// TODO: support parenthesis-less call params?
			return null;
		}
		return {
			openParen: openParen,
			params: parseOptionalCommaSeparated(parseOptionalExpr),
			closeParen: expectKind(TkParenClose),
		};
	}

	function parseArrayDecl(openBracket:Token):ArrayDecl {
		return switch (scanner.advance().kind) {
			case TkBracketClose:
				{openBracket: openBracket, elems: null, closeBracket: scanner.consume()};
			case _:
				{openBracket: openBracket, elems: parseCommaSeparated(parseExpr), closeBracket: expectKind(TkBracketClose)};
		};
	}

	function parseExpr():Expr {
		var expr = parseOptionalExpr();
		if (expr == null) throw new Exception("Expression expected");
		return expr;
	}

	function parseExprIdent(identToken:Token):Expr {
		return switch (identToken.text) {
			case _:
				return parseExprNext(EIdent(identToken));
		}
	}

	function parseExprNext(first:Expr):Expr {
		var token = scanner.advance();
		switch (token.kind) {
			case TkAsterisk:
				return parseBinop(first, OpMul);
			case TkSlash:
				return parseBinop(first, OpDiv);
			case _:
		}
		return first;
	}

	function parseBinop(a:Expr, ctor:Token->Binop):Expr {
		return makeBinop(a, ctor(scanner.consume()), parseExpr());
	}

	function makeBinop(a:Expr, op:Binop, b:Expr):Expr {
		// TODO: precedence
		return EBinop(a, op, b);
	}

	function parseOptionalTypeHint():Null<TypeHint> {
		var token = scanner.advance();
		return switch (token.kind) {
			case TkQuestion: TShortBool(scanner.consume());
			case TkPercent: TShortInt(scanner.consume());
			case TkHash: TShortFloat(scanner.consume());
			case TkDollar: TShortString(scanner.consume());
			case TkColon: TSyntaxType(scanner.consume(), parseSyntaxType());
			case _: null;
		}
	}

	function parseTypePath():TypePath {
		return {
			dotPath: parseDotPath(),
			params: parseOptionalTypeParams()
		};
	}

	function parseSyntaxType():SyntaxType {
		var token = scanner.advance();
		return switch (token.kind) {
			case TkIdent | TkKeyword(_):
				parseSyntaxTypeNext(TPath(parseTypePath()));
			case _:
				throw new Exception("Unexpected token for type: " + token);
		}
	}

	function parseOptionalTypeParams():Null<TypeParams> {
		switch (scanner.advance().kind) {
			case TkLt:
				return {
					lt: scanner.consume(),
					types: parseCommaSeparated(parseSyntaxType),
					gt: expectKind(TkGt),
				}
			case _:
				return null;
		}
	}

	function parseDotPath():DotPath {
		return parseSeparated(expectKind.bind(TkIdent), t -> t.kind == TkDot);
	}

	function parseDotPathNext(first:Token):DotPath {
		return parseSeparatedNext(first, expectKind.bind(TkIdent), t -> t.kind == TkDot);
	}

	function parseSyntaxTypeNext(first:SyntaxType):SyntaxType {
		return switch (scanner.advance().kind) {
			case TkBracketOpen:
				parseSyntaxTypeNext(TArray(first, scanner.consume(), expectKind(TkBracketClose)));
			case _:
				first;
		}
	}

	function parseCommaSeparated<T>(parsePart:Void->T):Separated<T> {
		return parseSeparated(parsePart, t -> t.kind == TkComma);
	}

	function parseOptionalCommaSeparated<T>(parsePart:Void->Null<T>):Null<Separated<T>> {
		return parseOptionalSeparated(parsePart, t -> t.kind == TkComma);
	}

	function parseOptionalSeparated<T>(parsePart:Void->Null<T>, checkSep:PeekToken->Bool):Null<Separated<T>> {
		var first = parsePart();
		if (first == null) return null;
		return parseSeparatedNext(first, parsePart, checkSep);
	}

	function parseSeparated<T>(parsePart:Void->T, checkSep:PeekToken->Bool):Separated<T> {
		var first = parsePart();
		return parseSeparatedNext(first, parsePart, checkSep);
	}

	function parseSeparatedNext<T>(first:T, parsePart:Void->T, checkSep:PeekToken->Bool):Separated<T> {
		var rest = [];
		while (true) {
			var token = scanner.advance();
			if (checkSep(token)) {
				var sep = scanner.consume();
				var part = parsePart();
				rest.push({sep: sep, element: part});
			} else {
				break;
			}
		}
		return {first: first, rest: rest};
	}

	function parseSequence<T>(parse:Void->Null<T>):Array<T> {
		var seq:Array<T> = [];
		while (true) {
			var item = parse();
			if (item != null) {
				seq.push(item);
			} else {
				break;
			}
		}
		return seq;
	}

	function expectOptional(check):Null<Token> {
		var token = scanner.advance();
		return if (check(token)) scanner.consume() else null;
	}

	function expect(check, msg):Token {
		var token = expectOptional(check);
		if (token == null) throw new haxe.Exception("Expected: " + msg + ", got: " + scanner.advance());
		return token;
	}

	function expectKind(kind):Token {
		return expect(t -> t.kind == kind, kind.getName());
	}

	function expectKeyword(expectedKwd:Keyword):Token {
		return expect(t -> switch (t.kind) {
			case TkKeyword(kwd) if (expectedKwd == expectedKwd): true;
			case _: false;
		}, expectedKwd.getName());
	}
}