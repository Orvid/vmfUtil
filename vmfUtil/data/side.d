﻿module data.side;

import data.entity : Entity;
import data.plane : Plane;
import data.textureaxis : TextureAxis;
import data.vec3r : Vec3r;

import std.conv : to;

struct Side
{
	size_t id;
	Plane plane;
	string material;
	TextureAxis uaxis;
	TextureAxis vaxis;
	real rotation;
	size_t lightmapScale;
	size_t smoothingGroups;

	Vec3r[] facePoints;

	this(Entity e)
	{
		this.id = e.id.to!size_t();
		this.plane = e.plane.to!Plane();
		this.material = e.material;
		this.uaxis = e.uaxis.to!TextureAxis();
		this.vaxis = e.vaxis.to!TextureAxis();
		this.rotation = e.rotation.to!real();
		this.lightmapScale = e.lightmapscale.to!size_t();
		this.smoothingGroups = e.smoothing_groups.to!size_t();
	}

	void updatePlane()
	{
		Vec3r[3] planePoints = void;
		Vec3r[] tmpVerts = new Vec3r[facePoints.length];
		tmpVerts[] = facePoints[];

		planePoints[0] = facePoints[0];

		foreach (ref vert; tmpVerts)
			vert -= planePoints[0];

		real maxCross = -1;
		size_t mi, mi2;

		foreach (i; 1..tmpVerts.length)
		{
			foreach (i2; i + 1..tmpVerts.length)
			{
				auto cpLen = tmpVerts[i].cross(tmpVerts[i2]).vectorLength();
				if (cpLen > maxCross)
				{
					maxCross = cpLen;
					mi = i;
					mi2 = i2;
				}
			}
		}

		if (!mi || !mi2)
			throw new Exception("Something is VERY wrong here!");
		planePoints[1] = facePoints[mi];
		planePoints[2] = facePoints[mi2];
		
		plane.points = planePoints;
	}

	Entity toEntity()
	{
		Entity e = new Entity();
		e.name = "side";
		e.id = id.to!string();
		e.plane = plane.toString();
		e.material = material;
		e.uaxis = uaxis.toString();
		e.vaxis = vaxis.toString();
		e.rotation = rotation.to!string();
		e.lightmapscale = lightmapScale.to!string();
		e.smoothing_groups = smoothingGroups.to!string();
		return e;
	}
}
