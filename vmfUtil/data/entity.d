module data.entity;

import data.connection : Connection;
import data.parsedenvironment : ParsedEnvironment;
import utils.indentedstreamwriter : IndentedStreamWriter;

__gshared Entity function(Entity)[string] registeredEntityTypes;

class Entity
{
	string name;
	Connection[] connections;
	string[string] properties;
	Entity[] children;
	Entity parent;

	auto copyFrom(Entity e)
	{
		this.name = e.name;
		this.connections = e.connections;
		this.properties = e.properties;
		this.children = e.children;
		this.parent = e.parent;
		return this;
	}

	string opDispatch(string member)(string value)
	{
		return properties[member] = value;
	}
	
	string opDispatch(string member)()
	{
		return properties[member];
	}

	private void writeConnections(IndentedStreamWriter wtr)
	{
		if (connections.length)
		{
			wtr.writeLine("connections");
			wtr.writeLine("{");
			wtr.indent++;
			foreach (conn; connections)
				conn.write(wtr);
			wtr.indent--;
			wtr.writeLine("}");
		}
	}

	void write(IndentedStreamWriter wtr)
	{
		wtr.writeLine(name);
		wtr.writeLine("{");
		wtr.indent++;

		if (auto entry = name in explicitEmissionOrders)
		{
			foreach (str; *entry)
			{
				if (auto val = str in properties)
					wtr.writeLine(`"%s" "%s"`, str, *val);
			}

			debug
			{
				import std.algorithm : countUntil;

				foreach (k; properties.byKey)
				{
					if ((*entry).countUntil!(e => e == k) == -1)
						throw new Exception("Property '" ~ k ~ "' wasn't in the explicit emission order list!");
				}
			}

			writeConnections(wtr);

			foreach (child; children)
				child.write(wtr);
		}
		else
		{
			import std.algorithm : any, filter, sort;

			bool solidChild = children.filter!(c => c.name == "solid").any;

			if ("id" in properties)
				wtr.writeLine(`"id" "%s"`, properties["id"]);
			if ("classname" in properties)
				wtr.writeLine(`"classname" "%s"`, properties["classname"]);

			foreach (k; properties.keys.sort!((a, b) => isKeyLessThan(a, b)))
			{
				if (k != "id" && k != "classname" && (solidChild || k != "origin"))
					wtr.writeLine(`"%s" "%s"`, k, properties[k]);
			}

			writeConnections(wtr);

			if (!solidChild && "origin" in properties)
				wtr.writeLine(`"origin" "%s"`, properties["origin"]);

			foreach (child; children)
				child.write(wtr);
		}

		
		wtr.indent--;
		wtr.writeLine("}");
	}
}

final class EntityTreeEnvironment : ParsedEnvironment
{
	Entity[] rootEntities;

	this(Entity[] rootEntities)
	{
		this.rootEntities = rootEntities;
	}

	void deepIter(void delegate(Entity e) func)
	{
		static void innerDeepIter(Entity ent, void delegate(Entity e) func)
		{
			func(ent);
			foreach(e; ent.children)
				innerDeepIter(e, func);
		}
		foreach (ent; rootEntities)
			innerDeepIter(ent, func);
	}

	override void write(IndentedStreamWriter wtr)
	{
		foreach (e; rootEntities)
			e.write(wtr);
	}
}

private:
bool isKeyLessThan(string a, string b)
{
	import std.conv : to;
	import std.ascii : toLower;

	if (a.length > 3 && b.length > 3 && a[0..3] == b[0..3] && a[0..3] == "row")
	{
		// TODO: This might cause issues if any other property starting with "row" exists
		return a[3..$].to!size_t() < b[3..$].to!size_t();
	}
	size_t i = 0;
	while (i < a.length && i < b.length && a[i].toLower() == b[i].toLower())
		i++;
	if (i == a.length)
		return a.length != b.length;
	else if (i == b.length)
		return false;
	else
		return a[i].toLower() < b[i].toLower();
}

__gshared immutable string[][string] explicitEmissionOrders;

shared static this()
{
	explicitEmissionOrders = [
		"camera": [
			"position",
			"look",
		],
		"cordon": [
			"mins",
			"maxs",
			"active",
		],
		"dispinfo": [
			"power",
			"startposition",
			"flags",
			"elevation",
			"subdiv",
		],
		"editor": [
			"color",
			"groupid",
			"visgroupid",
			"visgroupshown",
			"visgroupautoshown",
			"logicalpos",
		],
		"side": [
			"id",
			"plane",
			"material",
			"uaxis",
			"vaxis",
			"rotation",
			"lightmapscale",
			"smoothing_groups",
		],
		"versioninfo": [
			"editorversion",
			"editorbuild",
			"mapversion",
			"formatversion",
			"prefab",
		],
		"viewsettings": [
			"bSnapToGrid",
			"bShowGrid",
			"bShowLogicalGrid",
			"nGridSpacing",
			"bShow3DGrid",
		],
		"visgroup": [
			"name",
			"visgroupid",
			"color",
		],
		"world": [
			"id",
			"mapversion",
			"classname",
			"comment",
			"detailmaterial",
			"detailvbsp",
			"maxpropscreenwidth",
			"skyname",
		],
	];
}