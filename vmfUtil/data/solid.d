module data.solid;

import data.entity : Entity;
import data.plane : Plane;
import data.side : Side;
import data.vec3r : Vec3r;

import std.algorithm;
import std.array;
import std.conv : to;
import std.range : cycle;

struct Solid
{
	size_t id;
	Entity editorInfo;
	Side[] sides;

	@disable this();

	this(Entity self)
	{
		this.id = self.id.to!size_t();
		this.editorInfo = self.children.filter!(e => e.name == "editor").front;
		foreach (sd; self.children.filter!(e => e.name == "side"))
			sides ~= Side(sd);

		if (sides.length + 1 != self.children.length)
			throw new Exception("Unknown child present in a solid entity!");
	}

	void buildVertexes()
	{
		import std.stdio;
		writeln("Building for solid ", id);

		Vec3r[] points;

		for (size_t i = 0; i < sides.length; i++)
		{
			for (size_t i2 = i + 1; i2 < sides.length; i2++)
			{
				for (size_t i3 = i2 + 1; i3 < sides.length; i3++)
				{
					Vec3r pnt = void;
					if (Plane.intersectionOf(sides[i].plane, sides[i2].plane, sides[i3].plane, pnt))
					{
						points ~= pnt;
						writeln("\tFound (", pnt, ") is intersection for:");
						writeln("\t\t", sides[i].plane);
						writeln("\t\t", sides[i2].plane);
						writeln("\t\t", sides[i3].plane);
					}
				}
			}
		}

	}

	void rebuildPlanes()
	{
		foreach (s; sides)
			s.updatePlane();
	}

	Entity toEntity()
	{
		Entity e = new Entity();
		e.name = "solid";
		e.id = id.to!string();
		foreach (s; sides)
			e.children ~= s.toEntity();
		e.children ~= editorInfo;
		editorInfo.parent = e;
		return e;
	}
}

