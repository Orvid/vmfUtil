module data.connection;

import utils.indentedstreamwriter : IndentedStreamWriter;

struct Connection
{
	string eventName;
	string valueString; // TODO: Expand the value string to it's components

	this(string eventName, string valueString)
	{
		this.eventName = eventName;
		this.valueString = valueString;
	}

	void write(IndentedStreamWriter wtr)
	{
		wtr.writeLine(`"%s" "%s"`, eventName, valueString);
	}
}

