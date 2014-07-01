module data.vec3r;

import utils.formattedexception : FormattedException;

struct Vec3r
{
	//__gshared immutable zero = Vec3r(0, 0, 0);

	real x, y, z;

	@property bool isNormal() const
	{
		import std.math : isNormal;

		return x.isNormal || y.isNormal || z.isNormal;
	}

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
	
	Vec3r cross()(auto ref const Vec3r d2) inout
	{
		return Vec3r(
			this.y * d2.z - this.z * d2.y,
			this.z * d2.x - this.x * d2.z,
			this.x * d2.y - this.y * d2.x
		);
	}

	real dot()(auto ref const Vec3r d2) inout
	{
		return 
			  this.x * d2.x
			+ this.y * d2.y
			+ this.z * d2.z
		;
	}

	real vectorLength() inout
	{
		import std.math : sqrt;

		return sqrt(this.x ^^ 2 + this.y ^^ 2 + this.z ^^ 2);
	}


	Vec3r opOpAssign(string op)(auto ref const Vec3r v2)
	{
		mixin("return this = this " ~ op ~ " v2;");
	}

	Vec3r opBinary(string op)(auto ref const Vec3r v2) inout
		if (op == "-" || op == "+")
	{
		mixin("return Vec3r(this.x " ~ op ~ " v2.x, this.y " ~ op ~ " v2.y, this.z " ~ op ~ " v2.z);");
	}

	bool counterClockwiseFrom(ref const Vec3r other, ref const Vec3r center, int form, ref const Vec3r normal)
	{
		// Unfortunately, while the simple 3d computation works fine with 
		// point pairs that are not perpindicular to a coordinate axis, it
		// will occasionally fail on those points, so use a 2d version
		// instead.
		bool d2 = false;
		real vA1 = void, vA2 = void, vB1 = void, vB2 = void, vC1 = void, vC2 = void;
		// Once again, done to be cmovcc-able
		if (form == 1)
		{
			vA1 = this.y;
			vA2 = this.z;
			vB1 = other.y;
			vB2 = other.z;
			vC1 = center.y;
			vC2 = center.z;
			d2 = true;
		}

		if (form == 2)
		{
			vA1 = this.x;
			vA2 = this.z;
			vB1 = other.x;
			vB2 = other.z;
			vC1 = center.x;
			vC2 = center.z;
			d2 = true;
		}

		if (form == 3)
		{
			vA1 = this.x;
			vA2 = this.y;
			vB1 = other.x;
			vB2 = other.y;
			vC1 = center.x;
			vC2 = center.y;
			d2 = true;
		}

		if (d2)
		{
			real
				vAC1 = vA1 - vC1,
				vAC2 = vA2 - vC2,
				vBC1 = vB1 - vC1,
				vBC2 = vB2 - vC2
			;

			if (vAC1 >= 0 && vBC1 < 0)
				return true;
			if (vAC1 < 0 && vBC1 >= 0)
				return false;
			if (vAC1 == 0 && vBC1 == 0)
			{
				if (vAC2 >= 0 || vBC2 >= 0)
					return vA2 > vB2;
				return vB2 > vA2;
			}

			real dot = vAC1 * vBC2 - vBC1 * vAC2;
			if (dot < 0)
				return true;
			if (dot > 0)
				return false;

			return vAC1 ^^ 2 + vAC2 ^^ 2 > vBC1 ^^ 2 + vBC2 ^^ 2;
		}
		else
		{
			return (this - center).cross(other - center).dot(normal) < 0;
		}
	}
	
	int opCmp(ref const Vec3r b)
	{
		// This is written in this style to 
		// encourage the compiler to use cmovcc
		// instructions rather than branches.
		int ret = void;
		
		if (this.x > b.x)
			ret = 1;
		if (this.x < b.x)
			ret = -1;
		if (this.x == b.x)
		{
			if (this.y > b.y)
				ret = 1;
			if (this.y < b.y)
				ret = -1;
			if (this.y == b.y)
			{
				if (this.z > b.z)
					ret = 1;
				if (this.z < b.z)
					ret = -1;
				if (this.z == b.z)
					ret = 0;
			}
		}
		
		return ret;
	}

	string toString()
	{
		import std.string : format;
		
		return format("%s %s %s", x, y, z);
	}
}