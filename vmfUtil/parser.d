module parser;

import data.connection : Connection;
import data.entity : Entity, EntityTreeEnvironment, registeredEntityTypes;
import data.portal : Portal, PortalEnvironment;
import utils.indentedstreamwriter : IndentedStreamWriter;

EntityTreeEnvironment parse(string str)
{
	Entity[] parsedEntities;

	string prevStr;
	while (str.length && str != prevStr)
	{
		prevStr = str;
		auto ent = parseEntity(str);
		if (ent)
		{
			parsedEntities ~= ent;
		}
		consumeWhitespace(str);
	}

	return new EntityTreeEnvironment(parsedEntities);
}


PortalEnvironment parsePortals(string str)
{
	import data.vec3r : Vec3r;

	if (str[0..4] != "PRT1")
		throw new Exception("Invalid portal file!");
	str = str[4..$];
	consumeWhitespace(str);

	size_t clusterCount = parseUnsignedInteger(str);
	consumeWhitespace(str);

	size_t portalCount = parseUnsignedInteger(str);
	consumeWhitespace(str);

	Portal[] portals = new Portal[portalCount];
	foreach (i; 0..portalCount)
	{
		size_t pointCount = parseUnsignedInteger(str);
		consumeWhitespace(str);

		size_t clusterA = parseUnsignedInteger(str);
		consumeWhitespace(str);

		size_t clusterB = parseUnsignedInteger(str);
		consumeWhitespace(str);
		
		Vec3r[] parsed = new Vec3r[pointCount];
		foreach (i2; 0..pointCount)
		{
			if (str[0] != '(')
				throw new Exception("Expected '('!");
			str = str[1..$];

			size_t i3 = 0;
			while (str[i3] != ')')
				i3++;
			parsed[i2] = Vec3r.parse(str[0..i3 - 1]);
			str = str[i3 + 2..$];
		}

		portals[i] = Portal(parsed, clusterA, clusterB);
		consumeWhitespace(str);
	}

	return new PortalEnvironment(clusterCount, portals);
}

private:

Entity parseEntity(ref string str)
{
	auto ent = new Entity();
	size_t i = 0;

	while (i < str.length && str[i].isIdentifier)
		i++;

	ent.name = str[0..i];
	str = str[i..$];
	i = 0;
	consumeWhitespace(str);
	if (str[0] != '{')
		throw new Exception("Expected '{'!");
	str = str[1..$];

	while (str.length)
	{
		consumeWhitespace(str);
		if (str[0] == '"')
		{
			str = str[1..$];
			while (i < str.length && str[i] != '"')
				i++;
			string propName = str[0..i];
			str = str[i + 1..$];
			i = 0;
			consumeWhitespace(str);

			if (str[0] != '"')
				throw new Exception("Expected '\"'!");
			str = str[1..$];

			while (i < str.length && str[i] != '"')
				i++;
			if (ent.name == "connections")
				ent.connections ~= Connection(propName, str[0..i]);
			else
			{
				if (propName in ent.properties)
					throw new Exception("Duplicate property '" ~ propName ~ "' encountered!");
				ent.properties[propName] = str[0..i];
			}
			str = str[i + 1..$];
			i = 0;
		}
		else if (str[0] == '}')
		{
			str = str[1..$];

			if (ent.name in registeredEntityTypes)
				ent = registeredEntityTypes[ent.name](ent);
			return ent;
		}
		else if (isIdentifier(str[0]))
		{
			auto ch = parseEntity(str);

			if (ch.name == "connections")
				ent.connections = ch.connections;
			else
			{
				ch.parent = ent;
				ent.children ~= ch;
			}
		}
		else
			throw new Exception("Unexpected character!");
	}

	throw new Exception("Unexpected EOF! Expected a closing curly!");
}

void consumeWhitespace(ref string str)
{
	size_t i = 0;
	while (i < str.length)
	{
		switch (str[i])
		{
			case ' ':
			case '\r':
			case '\n':
			case '\t':
				i++;
				goto Continue;
			default:
				goto Break;
		}
	Break:
		break;
	Continue:
		continue;
	}
	str = str[i..$];
}

@property bool isIdentifier(char c)
{
	switch (c)
	{
		case 'a': .. case 'z':
		case 'A': .. case 'Z':
		case '_':
			return true;
		default:
			return false;
	}
}

size_t parseUnsignedInteger(ref string str)
{
	import std.conv : to;

	size_t i = 0;
	while (i < str.length)
	{
		switch (str[i])
		{
			case '0': .. case '9':
				i++;
				goto Continue;
			default:
				goto Break;
		}
	Break:
		break;
	Continue:
		continue;
	}
	size_t ret = str[0..i].to!size_t();
	str = str[i..$];
	return ret;
}