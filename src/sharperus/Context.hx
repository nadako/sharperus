package sharperus;

class Context {
	public final fileLoader:FileLoader;

	public function new(config:Config) {
		fileLoader = new FileLoader();
	}

	public function reportError(path:String, pos:Int, message:String) {
		var posStr = fileLoader.formatPosition(path, pos);
		Sys.println('$posStr: $message');
	}
}
