module modes.visleafmode;

import data.entity : Entity, EntityTreeEnvironment;
import modes.entitytreemode : EntityTreeProcessMode;
import modes.processmode : ProcessMode;

import std.algorithm;
import std.array;
import std.conv : to;
import std.string : toLower;

final class VisleafProcessMode : EntityTreeProcessMode
{
	shared static this() { register!VisleafProcessMode(); }
	final override @property string name() { return "visleaf"; }

	final override void processEntity(Entity e)
	{
		if (e.name == "side")
		{
			if (e.material.toLower() == "tools/visleaf")
			{
				auto ent = new Entity();
				ent.name = "entity";
				ent.classname = "func_viscluster";
				ent.id = nextID++.to!string();
				
				{
					auto solid = new Entity();
					solid.name = "solid";
					solid.id = nextID++.to!string();
					
					foreach (sd; e.parent.children)
					{
						auto nsd = new Entity();
						nsd.name = sd.name;
						nsd.properties = sd.properties.dup;
						nsd.id = nextID++.to!string();
						if (nsd.name == "side")
						{
							nsd.material = "TOOLS/TOOLSTRIGGER";
							sd.material = "visleaf";
						}
						nsd.parent = solid;
						solid.children ~= nsd;
					}
					
					solid.parent = ent;
					ent.children ~= solid;
				}
				
				{
					auto editorInfo = new Entity();
					editorInfo.name = "editor";
					editorInfo.color = "180 180 0";
					editorInfo.visgroupshown = "1";
					editorInfo.visgroupautoshown = "1";
					editorInfo.logicalpos = "[0 4000]";
					editorInfo.parent = ent;
					ent.children ~= editorInfo;
				}

				addEntityToTree(ent);
			}
			else if (e.material.toLower() == "tools/toolsviscluster")
			{
				auto ent = new Entity();
				ent.name = "entity";
				ent.classname = "func_viscluster";
				ent.comment = "from a viscluster tool";
				ent.id = nextID++.to!string();
				
				e.parent.parent.children = e.parent.parent.children.remove!(e2 => e2 == e.parent).array;
				ent.children ~= e.parent;
				e.parent.parent = ent;
				
				foreach (sd; e.parent.children)
				{
					if (sd.name == "side")
						sd.material = "TOOLS/TOOLSTRIGGER";
				}
				
				{
					auto editorInfo = new Entity();
					editorInfo.name = "editor";
					editorInfo.color = "180 180 0";
					editorInfo.visgroupshown = "1";
					editorInfo.visgroupautoshown = "1";
					editorInfo.logicalpos = "[0 4000]";
					editorInfo.parent = ent;
					ent.children ~= editorInfo;
				}

				addEntityToTree(ent);
			}
		}
	}

	final override void completeTreeProcessing(EntityTreeEnvironment env)
	{
		env.deepIter((Entity e) {
			if (e.name == "side" && e.material == "visleaf")
				e.material = "TOOLS/VISLEAF";
		});
		super.completeTreeProcessing(env);
	}

}
