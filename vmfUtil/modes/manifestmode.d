module modes.manifestmode;

import data.entity : Entity, EntityTreeEnvironment;
import data.plane : Plane;
import modes.entitytreemode : EntityTreeProcessMode;
import modes.processmode : ProcessMode;

import std.conv : to;
import std.string : toLower;

final class ManifestProcessMode : EntityTreeProcessMode
{
	shared static this() { register!ManifestProcessMode(); }
	final override @property string name() { return "manifest"; }
	final override @property bool writeOutput() { return false; }

	size_t[string] resourceManifestMap;
	Entity[] facesWithMisalignedPoints;

	final override void processEntity(Entity e)
	{
		if (e.name == "side")
		{
			resourceManifestMap[e.material.toLower()]++;
			
			Plane p = e.plane.to!Plane;
			if (
				   (p.points[0].x % 16 != 0)
				|| (p.points[0].y % 16 != 0)
				|| (p.points[0].z % 16 != 0)
				|| (p.points[1].x % 16 != 0)
				|| (p.points[1].y % 16 != 0)
				|| (p.points[1].z % 16 != 0)
				|| (p.points[2].x % 16 != 0)
				|| (p.points[2].y % 16 != 0)
				|| (p.points[2].z % 16 != 0)
			)
			{
				if (e.material.toLower() != "tools/toolsblocklight" && e.parent.parent.name != "entity")
					facesWithMisalignedPoints ~= e;
			}
		}
	}

	final override void completeTreeProcessing(EntityTreeEnvironment env)
	{
		info("Resources used:");
		foreach (k, v; resourceManifestMap)
		{
			info("%s: %s", k, v);
		}
		
		if (facesWithMisalignedPoints.length)
		{
			info("Faces with misaligned points found:");
			string lastBrushID = "";
			foreach (ent; facesWithMisalignedPoints)
			{
				if (ent.parent.id != lastBrushID)
				{
					lastBrushID = ent.parent.id;
					info("Brush %s has misaligned faces:", lastBrushID);
				}
				info("\tFace %s", ent.id);
			}
		}
	}
}

