module data.textureaxis;

import std.algorithm : countUntil;
import std.conv : to;

struct TextureAxis
{
	// TODO: Figure out what these fields actually mean
	//       and give them proper names for it.
	real a, b, c, d;
	real scale;

	this(string str)
	{
		this = parse(str);
	}

	static TextureAxis parse(string str)
	{
		TextureAxis n = void;
		if (str[0] != '[')
			throw new Exception("Expected '['!");
		str = str[1..$];

		auto aStr = str[0..str.countUntil(' ')];
		str = str[aStr.length + 1..$];
		n.a = aStr.to!real();

		auto bStr = str[0..str.countUntil(' ')];
		str = str[bStr.length + 1..$];
		n.b = bStr.to!real();

		auto cStr = str[0..str.countUntil(' ')];
		str = str[cStr.length + 1..$];
		n.c = cStr.to!real();

		auto dStr = str[0..str.countUntil(']')];
		str = str[dStr.length + 2..$];
		n.d = dStr.to!real();

		n.scale = str.to!real();

		return n;
	}

	string toString()
	{
		import std.string : format;

		return format("[%s %s %s %s] %s", a, b, c, d, scale);
	}
}
