module parser;

import data.entity : Entity, registeredEntityTypes;
import indentedstreamwriter : IndentedStreamWriter;

Entity[] parse(string str)
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

	return parsedEntities;
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
			ent.properties[propName] = str[0..i];
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
			ch.parent = ent;
			ent.children ~= ch;
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