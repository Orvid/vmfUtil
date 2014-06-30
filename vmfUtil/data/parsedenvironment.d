module data.parsedenvironment;

import utils.indentedstreamwriter : IndentedStreamWriter;

abstract class ParsedEnvironment
{
	abstract void write(IndentedStreamWriter wtr);
}

