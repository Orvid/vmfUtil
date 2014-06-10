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
		
		Vec3r d1 = Vec3r(p[1].x - p[0].x, p[1].y - p[0].y, p[1].z - p[0].z);
		Vec3r d2 = Vec3r(p[2].x - p[1].x, p[2].y - p[1].y, p[2].z - p[1].z);
		
		Vec3r cross = Vec3r(
			d1.y * d2.z - d1.z * d2.y,
			d1.z * d2.x - d1.x * d2.z,
			d1.x * d2.y - d1.y * d2.x
		);
		real dist = sqrt(cross.x ^^ 2 + cross.y ^^ 2 + cross.z ^^ 2);
		
		return Vec3r(cross.x / dist, cross.y / dist, cross.z / dist);
	}
}