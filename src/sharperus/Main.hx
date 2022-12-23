package sharperus;

import haxe.Exception;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

@:nullSafety(Off) var context:Context;

function main() {
	var args = Sys.args();
	if (args.length != 1) throw new haxe.Exception("Please specify configuration file");
	var config:Config = haxe.Json.parse(File.getContent(args[0]));

	context = new Context(config);

	var modules = [];
	for (sourceDir in config.sourceDirs) {
		walk(sourceDir, modules);
	}

	var tree = new TypedTree();
	// TODO: load externs here
	Typer.process(context, tree, modules);

	Filters.run(context, tree);

	var outDir = FileSystem.absolutePath(config.outputDir);
	for (module in tree.modules) {
		var moduleName;
		var dir = {
			var parts = module.path.split(".");
			moduleName = parts.pop();
			parts.unshift(outDir);
			parts.join("/");
		};
		createDirectory(dir);

		var out = GenCs.print(module);
		var path = dir + '/' + moduleName + ".cs";
		File.saveContent(path, out);
	}
}

function createDirectory(dir:String) {
	var tocreate = [];
	while (!FileSystem.exists(dir) && dir != '') {
		var parts = dir.split("/");
		tocreate.unshift(parts.pop());
		dir = parts.join("/");
	}
	for (part in tocreate) {
		if (part == '')
			continue;
		dir += "/" + part;
		try {
			FileSystem.createDirectory(dir);
		} catch (e:Any) {
			throw new Exception("unable to create dir: " + dir);
		}
	}
}

function walk(sourceDir:String, modules:Array<ParseTree.Module>) {
	function loop(dir) {
		for (name in FileSystem.readDirectory(dir)) {
			var absPath = dir + "/" + name;
			if (FileSystem.isDirectory(absPath)) {
				walk(absPath, modules);
			} else if (StringTools.endsWith(name, ".cxs")) {
				var modulePath = Path.withoutExtension(absPath.substring(sourceDir.length + 1)).split("/").join(".");
				var module = parseModule(absPath, modulePath);
				if (module != null) {
					modules.push(module);
				}
			}
		}
	}
	loop(sourceDir);
}

function parseModule(path:String, modulePath:String):Null<ParseTree.Module> {
	var content = context.fileLoader.getContent(path);
	var scanner = new Scanner(content);
	var parser = new Parser(scanner, path, modulePath);
	var parseTree = try parser.parse() catch (e) {
		context.reportError(path, scanner.pos, e.message);
		Sys.println(e.stack.toString());
		null;
	}
	if (parseTree != null) {
		checkParseTree(path, content, parseTree);
	}
	return parseTree;
}

function checkParseTree(path:String, expected:String, parseTree:ParseTree.Module) {
	var actual = Printer.print(parseTree);
	if (actual != expected) {
		Sys.println(actual);
		Sys.println("-=-=-=-=-");
		Sys.println(expected);
		throw new Exception('$path not the same');
	}
	// Sys.println(actual);
}