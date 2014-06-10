module data.entity;

import indentedstreamwriter : IndentedStreamWriter;

__gshared Entity function(Entity)[string] registeredEntityTypes;

class Entity
{
	string name;
	string[string] properties;
	Entity[] children;

	auto copyFrom(Entity e)
	{
		this.name = e.name;
		this.properties = e.properties;
		this.children = e.children;
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
		
		foreach (k, v; properties)
			wtr.writeLine(`"%s" "%s"`, k, v);
		
		foreach (child; children)
			child.write(wtr);
		
		wtr.indent--;
		wtr.writeLine("}");
	}
}
