module modes.cleanmode;

import data.camera : Camera;
import data.entity : Entity;
import data.plane : Plane;
import data.vec3r : Vec3r;
import modes.entitytreemode : EntityTreeProcessMode;
import modes.processmode : ProcessMode;

import std.algorithm;
import std.array;
import std.conv : to;
import std.string : toLower;

final class CleanProcessMode : EntityTreeProcessMode
{
	shared static this() { register!CleanProcessMode(); }
	final override @property string name() { return "clean"; }

	override void processEntity(Entity e)
	{		
		switch (e.name)
		{
			case "side":
			{				
				Plane p = e.plane.to!Plane;
				p.round();
				e.plane = p.toString();
				auto norm = p.normal;
				
				switch (e.material.toLower())
				{
					case "tools/toolsareaportal":
					case "tools/toolsblack":
					case "tools/toolsblock_los":
					case "tools/toolsblockbullets":
					case "tools/toolsblocklight":
					case "tools/toolsclip":
					case "tools/toolscontrolclip":
					case "tools/toolsdotted":
					case "tools/toolsfog":
					case "tools/toolshint":
					case "tools/toolsinvisible":
					case "tools/toolsinvisibledisplacement":
					case "tools/toolsnodraw":
					case "tools/toolsnpcclip":
					case "tools/toolsoccluder":
					case "tools/toolsorigin":
					case "tools/toolsplayerclip":
					case "tools/toolsskip":
					case "tools/toolsskybox":
					case "tools/toolsskybox2d":
					case "tools/toolsskyfog":
					case "tools/toolstrigger":
					{
						import std.math : abs, fmax;
						
						e.lightmapscale = "16";
						e.rotation = "0";
						e.smoothing_groups = "0";
						
						auto m = fmax(norm.x.abs, fmax(norm.y.abs, norm.z.abs));
						if (m == norm.x.abs)
						{
							e.uaxis = "[0 1 0 0] 0.25";
							e.vaxis = "[0 0 -1 0] 0.25";
						}
						else if (m == norm.y.abs)
						{
							e.uaxis = "[1 0 0 0] 0.25";
							e.vaxis = "[0 0 -1 0] 0.25";
						}
						else if (m == norm.z.abs)
						{
							e.uaxis = "[1 0 0 0] 0.25";
							e.vaxis = "[0 -1 0 0] 0.25";
						}
						else
							error("Unable to determine normal axis for texture UV of plane ID %s with normal of (%s) and m of %s!", e.id, norm, m);
						break;
					}
					case "tools/viscluster":
					{
						e.parent.children.filter!(edt => edt.name == "editor").front.visgroupid = visclusterGroupID.to!string();
						usedVisclusterVisgroup = true;
						goto case "tools/toolsnodraw";
					}
					case "tools/visleaf":
					{
						e.parent.children.filter!(edt => edt.name == "editor").front.visgroupid = visleafGroupID.to!string();
						usedVisleafVisgroup = true;
						goto case "tools/toolsnodraw";
					}
					default:
					{
						uint smooth = to!uint(e.smoothing_groups);
						
						if (norm.z == -1)
							smooth |= 1 << 1;
						else if (norm.z == 1)
							smooth |= 1 << 2;
						
						e.smoothing_groups = to!string(smooth);
						break;
					}
				}
				break;
			}
			case "camera":
			{
				auto camera = cast(Camera)e;
				camera.position = camera.position.round();
				camera.look = camera.look.round();
				break;
			}
			case "entity":
				switch(e.classname)
				{
					case "env_cubemap":
						e.origin = e.origin.to!Vec3r.round().toString();
						break;
					default:
						break;
				}
				break;
			default:
				break;
		}
	}

}

