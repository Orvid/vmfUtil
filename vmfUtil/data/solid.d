module data.solid;

import data.entity : Entity;
import data.side : Side;

import std.algorithm : filter;
import std.conv : to;

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

	Entity toEntity()
	{
		Entity e = new Entity();
		e.name = "solid";
		e.id = id.to!string();
		e.children ~= editorInfo;
		foreach (s; sides)
			e.children ~= s.toEntity();
		return e;
	}
}

