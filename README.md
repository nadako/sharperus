This is a small experimental transpiler for Cerberus-X programming language into C#.

Status: Very early stage, nothing is fully implemented, definitely NOT usable at all.

Very much inspired by my [AX3](https://github.com/innogames/ax3) coverter for AS3->Haxe (which is very much inspired by the Haxe compiler, lol).

Works pretty much like a compiler:
 - parse the code modules into parse tree structures, preserving all syntatic info
 - process parse tree, build consistent typed tree structure properly resolving all identifiers and assigning type info to every piece of code
 - run a number of filters that process typed tree to adapt the code for C# output
 - generate C# output from the processed typed tree
