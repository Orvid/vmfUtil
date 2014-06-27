module main;

import data.entity : Entity;


enum ProcessMode
{
	clean,
	visleaf,
	visleaf_gl,
	manifest,
	portals
}

void main(string[] args)
{
	import std.algorithm;
	import std.array;
	import std.conv : to;
	import std.file : read;
	import std.getopt : config, getopt;

	import parser : parse, parsePortals;

	string inputFileName;
	string outputFileName;
	ProcessMode mode = ProcessMode.clean;

	getopt(args,
		config.stopOnFirstNonOption,
		"out", &outputFileName,
		"mode", &mode
	);
	inputFileName = args[1];
	if (!outputFileName)
		outputFileName = inputFileName;

	if (mode == ProcessMode.portals)
	{
		import data.portal : Portal;
		import data.vec3r : Vec3r;
		import indentedstreamwriter : IndentedStreamWriter;
		import std.stdio : writeln;

		auto portalEnv = parsePortals(cast(string)read(inputFileName));
		size_t mergedPortals = 0;

		Portal[][size_t] visClusters;
		foreach (p; portalEnv.portals)
			visClusters[p.clusterA] ~= p;

		foreach (clusterID, ref portals; visClusters)
		{
			// TODO: Perhaps make this a lazy restart,
			//       as it would produce less re-testing
		Restart:
			for (size_t i = 0; i < portals.length; i++)
			{
				auto working = portals[i];

				foreach (p; portals.filter!(p => p.clusterB == working.clusterB && p != working))
				{
					size_t sameCount = 0;
					foreach (ref point; working.points)
						sameCount += p.points.countUntil!(pB => point == pB) != -1;

					if (sameCount > 2)
						throw new Exception("Don't know how to handle merging 2 portals with more than 2 matching points!");
					if (sameCount == 2)// && working.points.length == 4 && p.points.length == 4)
					{
						mergedPortals++;

//						writeln("Found 2 portals to merge:");
//						writeln(working);
//						writeln(p);

						auto workingPoints =
							// Leave the common points in 1 of the 2 pieces of the union
							p.points//.filter!(b => working.points.countUntil!(pB => b == pB) == -1)
							.setUnion(working.points.filter!(b => p.points.countUntil!(pB => b == pB) == -1))
							.array
						;
						if (workingPoints.length <= 2)
							throw new Exception("Something has gone wrong! A portal should have at least 3 points!");

						foreach (ref wp; workingPoints)
							wp += Vec3r(1, 1, 1);

						auto center = Vec3r(
							workingPoints.map!(p => p.x).sum / workingPoints.length,
							workingPoints.map!(p => p.y).sum / workingPoints.length,
							workingPoints.map!(p => p.z).sum / workingPoints.length
						);
						int form = 0;
						if (workingPoints.all!(p => p.x == workingPoints[0].x))
							form = 1;
						else if (workingPoints.all!(p => p.y == workingPoints[0].y))
							form = 2;
						else if (workingPoints.all!(p => p.z == workingPoints[0].z))
							form = 3;

						workingPoints = workingPoints.sort!((a, b) => a.counterClockwiseFrom(b, center, form)).array;

					RestartingWorkingPoints:
						for (size_t i2 = 0; i2 < workingPoints.length - 2; i2++)
						{
							if (workingPoints[i2].dot(workingPoints[i2 + 1].cross(workingPoints[i2 + 2])) == 0)
							{
								workingPoints = workingPoints.remove!(pnt => pnt == workingPoints[i2 + 1]);
								goto RestartingWorkingPoints;
							}
						}
						if (workingPoints[$ - 2].dot(workingPoints[$ - 1].cross(workingPoints[0])) == 0)
						{
							workingPoints = workingPoints.remove!(pnt => pnt == workingPoints[$ - 1]);
							goto RestartingWorkingPoints;
						}
						if (workingPoints[$ - 1].dot(workingPoints[0].cross(workingPoints[1])) == 0)
						{
							workingPoints = workingPoints.remove!(pnt => pnt == workingPoints[0]);
							goto RestartingWorkingPoints;
						}
						if (workingPoints.length <= 2)
							throw new Exception("Something has gone wrong! A portal should have at least 3 points!");

						foreach (ref wp; workingPoints)
							wp -= Vec3r(1, 1, 1);

						working.points = workingPoints;
						portals = portals.remove!(prt => prt == p);
						portals[i] = working;
						goto Restart;
					}
				}
			}
			// Made it through, do a bit of cleanup to make it easier to analyze
			portals = portals.sort!((a, b) => a < b).array;
		}

		writeln("Merged ", mergedPortals, " portals.");
		Portal[] finalPortals = new Portal[visClusters.values.map!(v => v.length).sum];
		size_t i = 0;
		foreach (v; visClusters.values.sort!((a, b) => a[0] < b[0])) // There should always be at least 1 portal per cluster.
		{
			finalPortals[i..i + v.length] = v[];
			i += v.length;
		}
		portalEnv.portals = finalPortals;
		writeln("Left with ", finalPortals.length, " portals.");

		IndentedStreamWriter wtr = new IndentedStreamWriter(outputFileName);
		portalEnv.write(wtr);
		wtr.close();
	}
	else
	{
		auto tree = parse(cast(string)read(inputFileName));

		size_t nextID = 0;
		foreach (ent; tree)
		{
			deepIter(ent, (Entity e) {
				if ("id" in e.properties)
				{
					size_t id = void;
					if (nextID <= (id = to!size_t(e.id)))
						nextID = id + 1;
				}
			});
		}

		Entity visgroups = tree.filter!(e => e.name == "visgroups").front;
		size_t nextVisgroupID = 0;
		foreach (ent; visgroups.children)
		{
			if ("visgroupid" in ent.properties)
			{
				size_t id = void;
				if (nextVisgroupID <= (id = to!size_t(ent.visgroupid)))
					nextVisgroupID = id + 1;
			}
		}

		bool usedVisleafVisgroup = false;
		size_t visleafGroupID = void;
		Entity visleafEntity = void;
		{
			auto q = visgroups.children.filter!(vs => vs.name == "visgroup" && "name" in vs.properties && vs.properties["name"] == "Visleafs");
			if (q.any)
			{
				visleafGroupID = q.front.visgroupid.to!size_t();
				usedVisleafVisgroup = true;
				visleafEntity = q.front;
			}
			else
			{
				Entity visleafGroup = new Entity();
				visleafGroup.name = "visgroup";
				visleafGroup.properties["name"] = "Visleafs";
				visleafGroupID = nextVisgroupID++;
				visleafGroup.visgroupid = visleafGroupID.to!string();
				visleafGroup.color = "248 185 126";
				visleafGroup.parent = visgroups;
				visgroups.children ~= visleafGroup;
				visleafEntity = visleafGroup;
			}
		}

		bool usedVisclusterVisgroup = false;
		size_t visclusterGroupID = void;
		Entity visclusterEntity = void;
		{
			auto q = visgroups.children.filter!(vs => vs.name == "visgroup" && "name" in vs.properties && vs.properties["name"] == "Visclusters");
			if (q.any)
			{
				visclusterGroupID = q.front.visgroupid.to!size_t();
				usedVisclusterVisgroup = true;
				visclusterEntity = q.front;
			}
			else
			{
				Entity visclusterGroup = new Entity();
				visclusterGroup.name = "visgroup";
				visclusterGroup.properties["name"] = "Visclusters";
				visclusterGroupID = nextVisgroupID++;
				visclusterGroup.visgroupid = visclusterGroupID.to!string();
				visclusterGroup.color = "248 185 126";
				visclusterGroup.parent = visgroups;
				visgroups.children ~= visclusterGroup;
				visclusterEntity = visclusterGroup;
			}
		}

		size_t[string] resourceManifestMap;
		Entity[] facesWithMisalignedPoints;

		foreach (ent; tree)
		{
			deepIter(ent, (Entity e) {
				import std.string : toLower;

				import data.plane : Plane;

				switch (mode)
				{
					case ProcessMode.clean:
					{
						import data.camera : Camera;
						import data.vec3r : Vec3r;

						switch (e.name)
						{
							case "side":
							{
								import std.array : join;

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
											throw new Exception("Unable to determine normal axis for texture UV!");
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
						break;
					}
					case ProcessMode.manifest:
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
						break;
					}
					case ProcessMode.visleaf_gl:
					case ProcessMode.visleaf:
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
											if (mode == ProcessMode.visleaf_gl)
												nsd.material = "DEV/DEV_MEASUREGENERIC01B";
											else
												nsd.material = "TOOLS/TOOLSTRIGGER";
											sd.material = "visleaf";
											//sd.material = "TOOLS/TOOLSHINT";
										}
										nsd.parent = solid;
										solid.children ~= nsd;
									}

									solid.parent = ent;
									ent.children ~= solid;
								}


								if (mode == ProcessMode.visleaf_gl)
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
												nsd.material = "DEV/DEV_MEASUREGENERIC01B";
										nsd.parent = solid;
										solid.children ~= nsd;
									}
									
									solid.parent = ent;
									e.parent.parent.children ~= solid;
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

								tree ~= ent;
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

								tree ~= ent;
							}
						}

						break;
					}
					default:
						throw new Exception("Unknown mode!");
				}
			});
		}


		// Finishing up
		switch (mode)
		{
			case ProcessMode.visleaf:
			case ProcessMode.visleaf_gl:
			{
				foreach (ent; tree)
				{
					deepIter(ent, (Entity e) {
						if (e.name == "side" && e.material == "visleaf")
							e.material = "TOOLS/VISLEAF";
					});
				}
				goto case ProcessMode.clean;
			}
			case ProcessMode.clean:
			{
				import indentedstreamwriter : IndentedStreamWriter;

				if (!usedVisleafVisgroup)
					visgroups.children = visgroups.children.remove!(c => c == visleafEntity).array;
				if (!usedVisclusterVisgroup)
					visgroups.children = visgroups.children.remove!(c => c == visclusterEntity).array;

				IndentedStreamWriter wtr = new IndentedStreamWriter(outputFileName);
				foreach (e; tree)
					e.write(wtr);
				wtr.close();
				break;
			}
			case ProcessMode.manifest:
			{
				import std.stdio : writeln;

				foreach (k, v; resourceManifestMap)
				{
					writeln(k, ": ", v);
				}

				if (facesWithMisalignedPoints.length)
				{
					writeln("Faces with misaligned points found:");
					string lastBrushID = "";
					foreach (ent; facesWithMisalignedPoints)
					{
						if (ent.parent.id != lastBrushID)
						{
							lastBrushID = ent.parent.id;
							writeln("Brush ", lastBrushID, " has misaligned faces:");
						}
						writeln("\tFace ", ent.id);
					}
				}
				break;
			}
			default:
				throw new Exception("Unknown process mode!");
		}
	}
}

void deepIter(Entity ent, void delegate(Entity e) func)
{
	func(ent);
	foreach(e; ent.children)
		deepIter(e, func);
}