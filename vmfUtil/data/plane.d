module data.plane;

import data.vec3r : Vec3r;

struct Plane
{
	Vec3r[3] points;

	this(string str)
	{
		this = parse(str);
	}

	static Plane parse(string str)
	{
		import std.algorithm : splitter;
		
		if (str[0] != '(')
			throw new Exception("Expected '('!");
		
		Vec3r[] parsed;
		foreach (val; str[1..$ - 1].splitter(") ("))
			parsed ~= Vec3r.parse(val);
		
		if (parsed.length != 3)
			throw new Exception("Expected 3 points!");
		
		Plane p = void;
		p.points[0..3] = parsed[0..3];
		return p;
	}
	
	Plane round()
	{
		foreach (ref p; points)
			p.round();

		return this;
	}
	
	@property Vec3r normal()
	{
		import std.math : sqrt;
		
		alias p = points;
				
		Vec3r cross = (p[1] - p[0]).cross(p[2] - p[1]);
		real dist = sqrt(cross.x ^^ 2 + cross.y ^^ 2 + cross.z ^^ 2);
		
		return Vec3r(cross.x / dist, cross.y / dist, cross.z / dist);
	}

	string toString()
	{
		import std.array : join;

		string[] outputArr;
		foreach (val; points)
			outputArr ~= val.toString();

		return "(" ~ outputArr.join(") (") ~ ")";
	}
}