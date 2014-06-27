module data.entity;

import indentedstreamwriter : IndentedStreamWriter;

__gshared Entity function(Entity)[string] registeredEntityTypes;

class Entity
{
	string name;
	string[string] properties;
	Entity[] children;
	Entity parent;

	auto copyFrom(Entity e)
	{
		this.name = e.name;
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
	
	void write(IndentedStreamWriter wtr)
	{
		wtr.writeLine(name);
		wtr.writeLine("{");
		wtr.indent++;

		if ("id" in properties)
			wtr.writeProperty!"id"(this);

		if (name == "side")
		{
			wtr.writeProperty!"plane"(this);
			wtr.writeProperty!"material"(this);
			wtr.writeProperty!"uaxis"(this);
			wtr.writeProperty!"vaxis"(this);
			wtr.writeProperty!"rotation"(this);
			wtr.writeProperty!"lightmapscale"(this);
			wtr.writeProperty!"smoothing_groups"(this);
		}
		else
		{
			foreach (k, v; properties)
			{
				if (k != "id")
					wtr.writeLine(`"%s" "%s"`, k, v);
			}
		}
		
		foreach (child; children)
			child.write(wtr);
		
		wtr.indent--;
		wtr.writeLine("}");
	}
}

private:
void writeProperty(string str)(IndentedStreamWriter wtr, Entity ent)
{
	wtr.writeLine(`"` ~ str ~ `" "%s"`, ent.properties[str]);
}