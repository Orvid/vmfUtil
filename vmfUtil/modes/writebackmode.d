﻿module modes.writebackmode;

import data.entity : Entity;
import data.solid : Solid;
import modes.entitytreemode : EntityTreeProcessMode;

final class WriteBackProcessMode : EntityTreeProcessMode
{
	shared static this() { register!WriteBackProcessMode(); }
	final override @property string name() { return "writeback"; }

	override void processEntity(Entity e)
	{
//		if (e.name == "solid")
//		{
//			auto sld = Solid(e);
//			sld.buildVertexes();
//			//sld.rebuildPlanes();
//			auto tmpEnt = sld.toEntity();
//			e.name = tmpEnt.name;
//			e.children = tmpEnt.children;
//			e.properties = tmpEnt.properties;
//		}
	}
}

