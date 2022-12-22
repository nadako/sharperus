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
		return; // TODO, obviously

		var typer = new Typer(context, tree);
		var tModules = [for (module in modules) {
			typer.processModule(module);
		}];
		for (f in typer.structureSetups) f();
		for (f in typer.exprTypings) f();
		trace(tModules);
	}

	function processModule(module:Module):TModule {
		var tmodule:TModule = {
			declarations: []
		}
		for (d in module.declarations) tmodule.declarations.push(typeDecl(tmodule, d));
		return tmodule;
	}

	function typeDecl(tmodule:TModule, d:Declaration):TDecl {
		switch d {
			case DGlobal(v):
				var tv:TGlobalVar = {type: null, init: null};
				switch (v.def) {
					case VDNormal(hint, init):
						if (hint != null) {
							structureSetups.push(() -> tv.type = resolveTypeHint(tmodule, hint));
						} else {
							tv.type = TInt;
						}
						if (init != null) {
							exprTypings.push(() -> typeVarInit(tv, init.expr));
						}
					case VDInferred(colonEquals, expr):
						exprTypings.push(() -> typeVarInit(tv, expr));
				}
				return {
					name: v.name.text,
					kind: TDGlobal(tv),
				};
			case _:
				throw "TODO";
		}
	}

	function resolveTypeHint(tmodule:TModule, hint:TypeHint):TType {
		return switch (hint) {
			case TShortBool(question): TBool;
			case TShortInt(percent): TInt;
			case TShortFloat(hash): TFloat;
			case TShortString(dollar): TString;
			case TSyntaxType(colon, type): resolveSyntaxType(tmodule, type);
		}
	}

	function resolveSyntaxType(tmodule:TModule, type:SyntaxType):TType {
		throw "TODO";
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
		throw "TODO";
	}
}
