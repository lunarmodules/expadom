--- XML DOM DocumentFragment Interface.
--
-- See the [DocumentFragment](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-B63ED1A3)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod DocumentFragment


local TYPES = require("expadom.constants").NODE_TYPES

local Class = require "expadom.class"
local Node = require "expadom.Node"

-- This is just an empty node

local methods = {}
function methods:__init()
	self.__prop_values.nodeType = TYPES.DOCUMENT_FRAGMENT_NODE
	self.__prop_values.nodeName = "#document-fragment"
	return Node.__init(self)
end

--- exports the XML.
-- @name DocumentFragment:write
-- @tparam[opt] array buffer an array to which the chunks can be added.
-- @tparam[opt] table namespacesInScope namespaceURIs indexed by prefix. For any namespace
-- not in this table, the definitions will be generated.
-- @return the buffer array
function methods:write(buffer, namespacesInScope)
	buffer = buffer or {}
	namespacesInScope = namespacesInScope or {}

	for _, child in ipairs(self.__prop_values.childNodes) do
		child:write(buffer, namespacesInScope)
	end
	return buffer
end

-- no tail call in case of errors/stacktraces
local DocumentFragment = Class("DocumentFragment", Node, methods)
return DocumentFragment
