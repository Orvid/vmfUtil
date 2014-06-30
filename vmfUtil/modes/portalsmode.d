module modes.portals;

import std.algorithm;
import std.array;

import data.parsedenvironment : ParsedEnvironment;
import data.plane : Plane;
import data.portal : Portal, PortalEnvironment;
import data.vec3r : Vec3r;

import parser : parsePortals;

import modes.processmode : ProcessMode;

final class PortalsProcessMode : ProcessMode
{
	shared static this() { register!PortalsProcessMode(); }
	final override @property string name() { return "portals"; }
	final override @property ParsedEnvironment function(string str) parseFunction() { return &parsePortals; }

	final override void process(ParsedEnvironment env)
	{		
		auto portalEnv = cast(PortalEnvironment)env;
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
					if (sameCount == 2)
					{
						mergedPortals++;
						
						auto workingPoints =
							// Leave the common points in 1 of the 2 pieces of the union
							//working.points
							p.points
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
						Vec3r normal = void; // Only initialize if form stays 0 (probably a bad idea)
						//						if (workingPoints.all!(p => p.x == workingPoints[0].x))
						//							form = 1;
						//						else if (workingPoints.all!(p => p.y == workingPoints[0].y))
						//							form = 2;
						//						else if (workingPoints.all!(p => p.z == workingPoints[0].z))
						//							form = 3;
						//						else
						normal = Plane(working.points).normal;
						
						workingPoints = workingPoints.sort!((a, b) => a.counterClockwiseFrom(b, center, form, normal)).array;
						
						// Now that they are sorted into the new composite plane, 
						// we need to eliminate the colinear points, so that we can
						// maintain the fact that there should only ever be 2 points
						// shared between mergable planes. (this simplifies the checking
						// process significantly)
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
		
		info("Merged %s portals.", mergedPortals);
		Portal[] finalPortals = new Portal[visClusters.values.map!(v => v.length).sum];
		size_t i = 0;
		foreach (v; visClusters.values.sort!((a, b) => a[0] < b[0])) // There should always be at least 1 portal per cluster.
		{
			finalPortals[i..i + v.length] = v[];
			i += v.length;
		}
		portalEnv.portals = finalPortals;
		info("Left with %s portals.", finalPortals.length);
	}
}

