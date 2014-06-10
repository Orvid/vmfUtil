module data.vec3r;

struct Vec3r
{
	real x, y, z;

	this(real x, real y, real z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	this(string str)
	{
		this = parse(str);
	}

	static Vec3r parse(string str)
	{
		import std.algorithm : countUntil;
		import std.conv : to;
		
		Vec3r p = void;
		
		auto xStr = str[0..str.countUntil(' ')];
		str = str[xStr.length + 1..$];
		p.x = to!real(xStr);
		
		auto yStr = str[0..str.countUntil(' ')];
		str = str[yStr.length + 1..$];
		p.y = to!real(yStr);
		p.z = to!real(str);
		
		return p;
	}

	Vec3r round()
	{
		import std.math : round;

		x = round(x);
		y = round(y);
		z = round(z);

		return this;
	}

	string toString()
	{
		import std.string : format;
		
		return format("%s %s %s", x, y, z);
	}
}