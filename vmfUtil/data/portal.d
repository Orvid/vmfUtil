module data.portal;

import data.parsedenvironment : ParsedEnvironment;
import data.vec3r : Vec3r;

struct Portal
{
	Vec3r[] points;
	size_t clusterA;
	size_t clusterB;


	int opCmp(ref const Portal b)
	{
		// This is written in this style to 
		// encourage the compiler to use cmovcc
		// instructions rather than branches.
		int ret;
		
		if (this.clusterA > b.clusterA)
			ret = 1;
		if (this.clusterA < b.clusterA)
			ret = -1;
		if (this.clusterA == b.clusterA)
		{
			if (this.clusterB > b.clusterB)
				ret = 1;
			if (this.clusterB < b.clusterB)
				ret = -1;
			if (this.clusterB == b.clusterB)
				ret = 0;
		}
		
		return ret;
	}

	string toString()
	{
		import std.array : join;
		import std.string : format;
		
		string[] outputArr;
		foreach (val; points)
			outputArr ~= val.toString();
		
		return format("%s %s %s (%s ) ", points.length, clusterA, clusterB, outputArr.join(" ) ("));
	}
}

final class PortalEnvironment : ParsedEnvironment
{
	import utils.indentedstreamwriter : IndentedStreamWriter;

	size_t clusterCount;
	Portal[] portals;

	this(size_t clusterCount, Portal[] portals)
	{
		this.clusterCount = clusterCount;
		this.portals = portals;
	}

	override void write(IndentedStreamWriter wtr)
	{
		wtr.writeLine("PRT1");
		wtr.writeLine("%s", clusterCount);
		wtr.writeLine("%s", portals.length);
		foreach (p; portals)
			wtr.writeLine("%s", p);
	}
}