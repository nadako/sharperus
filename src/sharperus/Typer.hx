package sharperus;

import sharperus.ParseTree;
import sharperus.TypedTree;

class Typer {
	final context:Context;
	final tree:TypedTree;

	final structureSetups:Array<()->Void> = [];
	final exprTypings:Array<()->Void> = [];

	function new(context, tree) {
		this.context = context;
		this.tree = tree;
	}

	public static function process(context:Context, tree:TypedTree, modules:Array<Module>) {
		var typer = new Typer(context, tree);
		for (module in modules) {
			typer.processModule(module);
		}
		for (f in typer.structureSetups) f();
		for (f in typer.exprTypings) f();

		for (m in @:privateAccess tree.modules) {
			for (d in m.declarations)
				trace(d);
		}
	}

	function processModule(module:Module) {
		var tmodule = new TModule(module.path, module.file);
		tree.addModule(tmodule);
		for (d in module.declarations) {
			typeDecl(tmodule, d);
		}
	}

	function typeDecl(module:TModule, d:Declaration) {
		switch (d) {
			case DStrict(keyword):
				module.declarations.push(TDStrict(keyword));
			case DImport(keyword, dotPath):
				trace("TODO: import");
			case DGlobal(v):
				typeModuleGlobal(module, v);
			case DConst(c):
				typeModuleConst(module, c);
			case DFunction(f):
				typeModuleFunction(module, f);
			case DClass(c):
				typeModuleClass(module, c);
			}
	}

	function typeModuleGlobal(module:TModule, v:VarDecl) {
		var tv:TGlobalVar = {name: v.name.text, type: null, init: null};
		switch (v.def) {
			case VDNormal(hint, init):
				if (hint == null) {
					// unhinted, Int is the default
					tv.type = TTInt;
				} else {
					// otherwise resolve type hint
					structureSetups.push(() -> tv.type = resolveTypeHint(module, hint));
				}
				if (init != null) {
					// if there's an initializer, type it
					exprTypings.push(() -> typeVarInit(tv, init.expr));
				}
			case VDInferred(colonEquals, expr):
				// type initializer
				exprTypings.push(() -> typeVarInit(tv, expr));
		}
		module.declarations.push(TDGlobal(tv));
	}

	function typeModuleConst(module:TModule, c:ConstDecl) {
		trace("TODO: const");
	}

	function typeModuleFunction(module:TModule, f:FunctionDecl) {
		trace("TODO: function");
	}

	function typeModuleClass(module:TModule, c:ClassDecl) {
		var tc:TClassDecl = {
			syntax: {
				classKeyword: c.classKeyword,
				name: c.name,
				end: c.end,
			},
			name: c.name.text,
			members: [],
		};
		module.declarations.push(TDClass(tc));
	}

	function resolveTypeHint(tmodule:TModule, hint:TypeHint):TType {
		return switch (hint) {
			case TShortBool(question): TTBool;
			case TShortInt(percent): TTInt;
			case TShortFloat(hash): TTFloat;
			case TShortString(dollar): TTString;
			case TSyntaxType(colon, type): resolveSyntaxType(tmodule, type);
		}
	}

	function resolveSyntaxType(tmodule:TModule, type:SyntaxType):TType {
		return switch (type) {
			case TArray(elemType, _):
				TTArray(resolveSyntaxType(tmodule, elemType));

			case TPath({dotPath: {first: {kind: TkKeyword(kwd)}, rest: []}, params: null}):
				switch (kwd) {
					case KwdBool: TTBool;
					case KwdInt: TTInt;
					case KwdFloat: TTFloat;
					case KwdString: TTString;
					case KwdObject: TTObject;
					case KwdVoid: TTVoid;
					case _:
						throw "Unhandled built-in type: " + kwd;
				}

			case TPath(path):
				trace("TODO: " + path);
				TTObject;
		};
	}

	function typeVarInit(tv:TGlobalVar, e:Expr) {
		var exprTyper = new ExprTyper();
		tv.init = exprTyper.typeExpr(e, tv.type);
		if (tv.type == null) tv.type = tv.init.type;
	}
}

class ExprTyper {
	public function new() {
	}

	public function typeExpr(e:Expr, expectedType:Null<TType>):TExpr {
		return switch (e) {
			case EIdent(ident):
				throw "TODO";
			case ELiteral(l):
				typeLiteral(l, expectedType);
			case EArrayDecl(d):
				throw "TODO";
			case EUnop(op, e):
				throw "TODO";
			case EBinop(left, op, right):
				throw "TODO";
			case ENew(e):
				throw "TODO";
			case EMember(e, dot, name):
				throw "TODO";
			case ECall(e, params):
				throw "TODO";
			case EIndex(e, openBracket, i, closeBracket):
				throw "TODO";
		};
	}

	function typeLiteral(l:Literal, expectedType:Null<TType>):TExpr {
		return switch (l) {
			case LDecInt(t): mk(TELiteral(TLInt(TIDec(t))), TTInt, expectedType);
			case LHexInt(t): mk(TELiteral(TLInt(TIHex(t))), TTInt, expectedType);
			case LBool(t): mk(TELiteral(TLBool(t)), TTBool, expectedType);
			case LFloat(t): mk(TELiteral(TLFloat(t)), TTFloat, expectedType);
			case LString(t): mk(TELiteral(TLString(t)), TTString, expectedType);
			case LChar(t): mk(TELiteral(TLChar(t)), TTChar, expectedType);
		}
	}

	static inline function mk(kind:TExprKind, type:TType, expectedType:TType):TExpr {
		return {kind: kind, type: type, expectedType: expectedType};
	}
}
