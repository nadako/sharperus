package sharperus;

import haxe.Exception;
import sys.FileSystem;

@:nullSafety(Off) var context:Context;

function main() {
	var args = Sys.args();
	if (args.length != 1) throw new haxe.Exception("Please specify configuration file");
	var config:Config = haxe.Json.parse(sys.io.File.getContent(args[0]));

	context = new Context(config);

	var modules = [];
	for (sourceDir in config.sourceDirs) {
		walk(sourceDir, modules);
	}

	var tree = new TypedTree();
	// TODO: load externs here
	Typer.process(context, tree, modules);

	Filters.run(context, tree);

	var outdir = FileSystem.absolutePath(config.outputDir);
	// TODO: write .cs files
}


function walk(dir:String, modules:Array<ParseTree.Module>) {
	function loop(dir) {
		for (name in FileSystem.readDirectory(dir)) {
			var absPath = dir + "/" + name;
			if (FileSystem.isDirectory(absPath)) {
				walk(absPath, modules);
			} else if (StringTools.endsWith(name, ".cxs")) {
				var module = parseModule(absPath);
				if (module != null) {
					modules.push(module);
				}
			}
		}
	}
	loop(dir);
}

function parseModule(path:String):Null<ParseTree.Module> {
	var content = context.fileLoader.getContent(path);
	var scanner = new Scanner(content);
	var parser = new Parser(scanner, path);
	var parseTree = try parser.parse() catch (e) {
		context.reportError(path, scanner.pos, e.message);
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
	Sys.println(actual);
}