module modes.cleanmode;

import data.camera : Camera;
import data.entity : Entity;
import data.plane : Plane;
import data.solid : Solid;
import data.vec3r : Vec3r;
import modes.entitytreemode : EntityTreeProcessMode;
import modes.processmode : ProcessMode;

import std.algorithm;
import std.array;
import std.conv : to;
import std.math : fabs;
import std.string : toLower;

final class CleanProcessMode : EntityTreeProcessMode
{
	shared static this() { register!CleanProcessMode(); }
	final override @property string name() { return "clean"; }

	Solid[][Entity] solidGroups;

	override void processEntity(Entity e)
	{		
		switch (e.name)
		{
			case "solid":
			{
				if (!e.parent)
					error("Somehow have a solid without a parent!");
				solidGroups[e.parent] ~= Solid(e);
				break;
			}
			case "side":
			{				
				Plane p = e.plane.to!Plane;
				p.round();
				auto norm = p.normal;
				if (!norm.isNormal)
				{
					p = e.plane.to!Plane;
					norm = p.normal;

					if (!norm.isNormal)
						error("Invalid normal (%s) for %s!", norm, p);
					else
						warning("Plane %s is too small to be properly rounded!", e.id);
				}
				else
					e.plane = p.toString();

				foreach (dispInfo; e.children.filter!(c => c.name == "dispinfo"))
				{
					import std.range : chain;

					bool allZero = true;
					foreach (dioff; dispInfo.children.filter!(c => c.name == "distances").front.properties.byValue.chain(dispInfo.children.filter!(c => c.name == "offsets").front.properties.byValue).joiner(" ").array.splitter(" "))
					{
						real val = to!real(dioff);
						if (fabs(val) > 0.001) // account for imperceptibly non-flat surfaces. 
						{
							if (e.id == "17083")
								info("Not zero because of %s", val);
							allZero = false;
							break;
						}
					}

					if (allZero)
					{
						e.children = e.children.remove!(c => c == dispInfo);
						info("Removing displacement info from perfectly flat plane %s", e.id);
					}

					break;
				}
				
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
						{
							error("Unable to determine normal axis for texture UV of plane ID %s with normal of (%s) and m of %s!", e.id, norm, m);
						}
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

