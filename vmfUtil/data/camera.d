module data.camera;

import std.conv : to;

import data.entity : Entity, registeredEntityTypes;
import data.vec3r : Vec3r;

final class Camera : Entity
{
	shared static this()
	{
		registeredEntityTypes["camera"] = (e) => new Camera().copyFrom(e);
	}

@property:
	Vec3r position() { return properties["position"][1..$ - 1].to!Vec3r; }
	string position(Vec3r vec) { return properties["position"] = "[" ~ vec.toString() ~ "]"; }

	Vec3r look() { return properties["look"][1..$ - 1].to!Vec3r; }
	string look(Vec3r vec) { return properties["look"] = "[" ~ vec.toString() ~ "]"; }
}
