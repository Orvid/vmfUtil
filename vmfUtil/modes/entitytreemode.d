module modes.entitytreemode;

import data.entity : Entity, EntityTreeEnvironment;
import data.parsedenvironment : ParsedEnvironment;
import modes.processmode : ProcessMode;

import parser : parse;

import std.algorithm;
import std.array;
import std.conv : to;

abstract class EntityTreeProcessMode : ProcessMode
{
	final override @property ParsedEnvironment function(string str) parseFunction() { return &parse; }

	size_t nextID = 0;

	Entity visgroups = null;
	size_t nextVisgroupID = 0;

	bool usedVisleafVisgroup = false;
	size_t visleafGroupID = void;
	Entity visleafEntity = void;

	bool usedVisclusterVisgroup = false;
	size_t visclusterGroupID = void;
	Entity visclusterEntity = void;

	private EntityTreeEnvironment workingEnvironment;

	final override void process(ParsedEnvironment env)
	{
		auto treeEnv = cast(EntityTreeEnvironment)env;
		this.workingEnvironment = treeEnv;

		treeEnv.deepIter((Entity e) {
			if ("id" in e.properties)
			{
				size_t id = void;
				if (nextID <= (id = to!size_t(e.id)))
					nextID = id + 1;
			}
		});

		visgroups = treeEnv.rootEntities.filter!(e => e.name == "visgroups").front;

		foreach (ent; visgroups.children)
		{
			if ("visgroupid" in ent.properties)
			{
				size_t id = void;
				if (nextVisgroupID <= (id = to!size_t(ent.visgroupid)))
					nextVisgroupID = id + 1;
			}
		}

		// visleafs group
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

		// visclusters group
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

		treeEnv.deepIter(e => processEntity(e));

		completeTreeProcessing(treeEnv);
	}

protected:
	final void addEntityToTree(Entity e)
	{
		workingEnvironment.rootEntities ~= e;
	}

	abstract void processEntity(Entity e);

	void completeTreeProcessing(EntityTreeEnvironment env)
	{
		if (!usedVisleafVisgroup)
			visgroups.children = visgroups.children.remove!(c => c == visleafEntity).array;
		if (!usedVisclusterVisgroup)
			visgroups.children = visgroups.children.remove!(c => c == visclusterEntity).array;
	}
}

