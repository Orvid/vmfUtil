module main;

import std.getopt : config, getopt;
import modes.processmode : ProcessMode;

void main(string[] args)
{
	import std.getopt : config, getopt;

	string inputFileName;
	string outputFileName;
	string mode = "clean";

	getopt(args,
		config.stopOnFirstNonOption,
		"out", &outputFileName,
		"mode", &mode
	);
	inputFileName = args[1];
	if (!outputFileName)
		outputFileName = inputFileName;

	ProcessMode.runMode(mode, inputFileName, outputFileName);
}

