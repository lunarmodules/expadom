--- XML DOM DocumentType Interface.
--
-- The DOM level 2 does not specify how to interact with the DTD, hence
-- has not been implemented other than the wrapper for external DTD definitions,
-- the generated internal subset will always be empty for now.
--
-- See the [DocumentType](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-412266927)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod DocumentType

local Class = require "expadom.class"
local Node = require "expadom.Node"
local NamedNodeMap = require "expadom.NamedNodeMap"
local TYPES = require("expadom.constants").NODE_TYPES
local format = string.format


--- Properties of the `DocumentType` class, beyond the `Node` class
-- @field name the DTD name (readonly)
-- @field entities `NamedNodeMap` of entities (readonly) - not implemented
-- @field notations `NamedNodeMap` of notations (readonly) - not implemented
-- @field publicId (string) the PI `publicId` (readonly)
-- @field systemId (string) the PI `systemId` (readonly)
-- @field internalSubset (string) the PI `internalSubset` (readonly) - not implemented
-- @table properties
local properties = {
	name = { readonly = true },
	entities = { readonly = true },
	notations = { readonly = true },
	publicId = { readonly = true },
	systemId = { readonly = true },
	internalSubset = { readonly = true },
	-- Node overrides
	nodeName = {
		readonly = true,
		get = function(self) return self.__prop_values.name end,
	},
}

local methods = {}


function methods:__init()
	self.__prop_values.nodeType = TYPES.DOCUMENT_TYPE_NODE

	local ok, err = Node.__init(self)
	if not ok then
		return ok, err
	end

	-- TODO: ensure we have a name here, from the spec:
	-- The name of DTD; i.e., the name immediately following the DOCTYPE keyword.
	self.__prop_values.nodeName = self.__prop_values.name
	self.__prop_values.entities = NamedNodeMap { parentNode = self }
	self.__prop_values.notations = NamedNodeMap { parentNode = self }
	return true
end


--- exports the XML.
-- @name DocumentType:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	local i = #buffer+1
	buffer[i] = "<!DOCTYPE "
	buffer[i+1] = self.__prop_values.name

	local publicId = self.__prop_values.publicId
	local systemId = self.__prop_values.systemId
	if publicId then
		buffer[i+2] = format(' PUBLIC "%s" "%s"', publicId, systemId)
		i = i + 3
	elseif systemId then
		buffer[i+2] = format(' SYSTEM "%s"', systemId)
		i = i + 3
	else
		i = i + 2
	end

	local internalSubset = self.__prop_values.internalSubset
	if internalSubset then
		buffer[i] = format(" [%s]>", internalSubset)
	else
		buffer[i] = ">"
	end

	return buffer
end


-- no tail call in case of errors/stacktraces
local DocumentType = Class("DocumentType", Node, methods, properties)
return DocumentType
