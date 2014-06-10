module main;

import std.conv : to;
import std.file : read;

import indentedstreamwriter;
import parser;

void main(string[] args)
{
	auto tree = parse(cast(string)read(args[1]));

	foreach (ent; tree)
	{
		deepIter(ent, (Entity e) {
			import data.camera : Camera;
			import data.plane : Plane;
			import data.vec3r : Vec3r;

			switch (e.name)
			{
				case "side":
					//if ("plane" in e.properties)
					{
						import std.array : join;

						Plane p = e.plane.to!Plane;
						p.round();

						string[] outputArr;
						foreach (val; p.points)
							outputArr ~= val.toString();
						e.plane = "(" ~ outputArr.join(") (") ~ ")";
						
						//if ("material" in e.properties)
						{
							import std.string : toLower;

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
										throw new Exception("Unable to determine normal axis for texture UV!");
									break;
								}
								default:
									uint smooth = to!uint(e.smoothing_groups);

									if (norm.z == -1)
										smooth |= 1 << 1;
									else if (norm.z == 1)
										smooth |= 1 << 2;

									e.smoothing_groups = to!string(smooth);
									break;
							}
						}
					}
					break;
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
		});
	}

	IndentedStreamWriter wtr = new IndentedStreamWriter("TestOutput.vmf");
	foreach (e; tree)
		e.write(wtr);
	wtr.close();
}

void deepIter(Entity ent, void delegate(Entity e) func)
{
	func(ent);
	foreach(e; ent.children)
		deepIter(e, func);
}