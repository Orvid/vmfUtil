module utils.formattedexception;


final class FormattedException : Exception
{
	this(string file = __FILE__, size_t line = __LINE__, ARGS...)(string msg, ARGS args)
	{
		import std.string : format;
		
		super(format(msg, args), file, line);
	}
}