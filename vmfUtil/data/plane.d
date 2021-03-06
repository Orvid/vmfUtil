﻿module data.plane;

import data.vec3r : Vec3r;
import utils.formattedexception : FormattedException;

struct Plane
{
	Vec3r[3] points;

	this(Vec3r[] srcPts)
	{
		this.points[] = srcPts[0..3];
	}

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

	// TODO: Make this @property again, it was removed because of an issue with DMD
	Vec3r normal() inout
	{
		import std.math : sqrt;
		
		alias p = points;
				
		Vec3r cross = (p[1] - p[0]).cross(p[2] - p[1]);
		real dist = sqrt(cross.x ^^ 2 + cross.y ^^ 2 + cross.z ^^ 2);
		//if (dist == 0)
		//	throw new FormattedException("For points (%s) (%s) (%s), with a cross product of (%s) the square root of the sum of it's squared components is zero!", p[0], p[1], p[2], cross);

		return Vec3r(cross.x / dist, cross.y / dist, cross.z / dist);
	}

	Vec3r normal(out real distance) inout
	{
		import std.math : sqrt;
		
		alias p = points;
		
		Vec3r cross = (p[1] - p[0]).cross(p[2] - p[1]);
		distance = sqrt(cross.x ^^ 2 + cross.y ^^ 2 + cross.z ^^ 2);
		
		return Vec3r(cross.x / distance, cross.y / distance, cross.z / distance);
	}

	static bool intersectionOf()(auto ref const Plane a, auto ref const Plane b, auto ref const Plane c, out Vec3r result)
	{
		real ad = void, bd = void, cd = void;
		auto an = a.normal(ad), bn = b.normal(bd), cn = c.normal(cd);
		real denom = an.dot(bn.cross(cn));

		// Check if there really is an intersection
		if (denom < real.epsilon) 
			return false;

		result = (
			(bn.cross(cn) * ad) +
			(cn.cross(an) * bd) +
			(an.cross(bn) * cd)
		) / -denom;

		return true;
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