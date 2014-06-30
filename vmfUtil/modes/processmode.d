module modes.processmode;

import data.parsedenvironment : ParsedEnvironment;

abstract class ProcessMode
{
public:
	@property bool writeOutput() { return true; }
	abstract @property string name();
	abstract @property ParsedEnvironment function(string str) parseFunction();
	abstract void process(ParsedEnvironment env);


	static void runMode(string modeName, string inputFileName, string outputFileName)
	{
		import utils.indentedstreamwriter : IndentedStreamWriter;

		ProcessMode mode = registeredProcessModes[modeName];

		auto env = mode.parseFunction()(readFile(inputFileName));
		mode.process(env);
		if (mode.writeOutput)
		{
			auto wtr = new IndentedStreamWriter(outputFileName);
			env.write(wtr);
			wtr.close();
		}
	}

protected:
	__gshared ProcessMode[string] registeredProcessModes;

	static void register(T)()
	{
		auto pm = new T();
		registeredProcessModes[pm.name] = pm;
	}

	static void error(string file = __FILE__, size_t line = __LINE__, ARGS...)(string msg, ARGS args)
	{
		import std.string : format;
		
		throw new Exception(format(msg, args), file, line);
	}

	static void info(ARGS...)(string msg, ARGS args)
	{
		import std.stdio : writefln;

		writefln(msg, args);
	}

	static string readFile(string fileName)
	{
		import std.file : read;

		return cast(string)read(fileName);
	}

	static void writeFile(string fileName, string data)
	{
		import std.file : write;

		write(fileName, data);
	}
}
