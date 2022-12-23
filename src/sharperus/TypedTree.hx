package sharperus;

import haxe.Exception;
import sharperus.ParseTree;

class TypedTree {
	public final modules:Map<String, TModule>;

	public function new() {
		modules = [];
	}

	public function getModule(path:String):Null<TModule> {
		return modules[path];
	}

	public function addModule(module:TModule) {
		if (modules.exists(module.path)) {
			throw new Exception("Module already exists: " + module.path);
		}
		modules[module.path] = module;
	}
}

class TModule {
	public final file:String;
	public final path:String;
	public final declarations:Array<TDecl>;

	public function new(path, file) {
		this.path = path;
		this.file = file;
		declarations = [];
	}
}

enum TDecl {
	TDStrict(syntax:Token);
	TDGlobal(g:TGlobalVar);
	TDClass(c:TClassDecl);
}

typedef TGlobalVar = {
	var name:String;
	var type:TType;
	var init:Null<TExpr>;
}

typedef TClassDecl = {
	var syntax:{
		var classKeyword:Token;
		var name:Token;
		var end:BodyEnd;
	};
	var name:String;
	var members:Array<TClassMember>;
}

typedef TClassMember = {

}

enum TType {
	TTVoid;
	TTBool;
	TTInt;
	TTFloat;
	TTString;
	TTChar;
	TTObject;
	TTArray(elemType:TType);
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
	TLBool(syntax:Token);
	TLInt(i:TIntLiteral);
	TLFloat(syntax:Token);
	TLString(syntax:Token);
	TLChar(syntax:Token);
}

enum TIntLiteral {
	TIDec(syntax:Token);
	TIHex(syntax:Token);
}

