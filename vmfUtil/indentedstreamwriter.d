module indentedstreamwriter;

private import std.file : exists, mkdirRecurse;
private import std.path : dirName;
private import std.stdio : File;

final class IndentedStreamWriter
{
private:
	bool mCurrentLineIndented;
	bool mClosed;
	int mIndent;
	File mInnerFile;
	
public:
	this(string fileName)
	{
		string dName = dirName(fileName);
		if (dName != "." && !exists(dName))
			mkdirRecurse(dName);
		this.mInnerFile = File(fileName, "w");
	}
	
	~this()
	{
		if (!mClosed)
			close();
	}
	
	@property auto ref int indent() { return mIndent; }
	
	void close()
	{
		if (!mClosed)
		{
			mClosed = true;
			flush();
			mInnerFile.close();
		}
	}
	
	void flush()
	{
		mInnerFile.flush();
	}
	
	private void ensureIndent()
	{
		if (!mCurrentLineIndented)
		{
			for (int i = 0; i < mIndent; i++)
				mInnerFile.write("\t");
			mCurrentLineIndented = true;
		}
	}

	void write(Char, A...)(in Char[] message, A args)
	{
		ensureIndent();
		static if (args.length)
			mInnerFile.writef(message, args);
		else
			mInnerFile.write(message);
		
		debug flush();
	}
	
	void writeLine()()
	{
		ensureIndent();
		mInnerFile.writeln();
		mCurrentLineIndented = false;

		debug flush();
	}
	
	void writeLine(Char, A...)(in Char[] message, A args)
	{
		ensureIndent();
		static if (args.length)
			mInnerFile.writefln(message, args);
		else
			mInnerFile.writeln(message);
		mCurrentLineIndented = false;
		
		debug flush();
	}
	
}