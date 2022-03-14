--- XML DOM Attribute Interface.
--
-- See the [Attr](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-637646024)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod Attribute


local Class = require "expadom.class"
local Node = require "expadom.Node"
local Text = require "expadom.Text"

local constants = require "expadom.constants"
local TYPES = constants.NODE_TYPES


--- Properties of the `Attribute` class, beyond the `Node` class
-- @field name (string) the attribute name (readonly)
-- @field value (string) the contents of the attribute
-- @field nodeValue (string) same as field `value` (readonly)
-- @field ownerElement `Element` object this attribute belongs to (readonly)
-- @table properties
local properties = {
	name = { readonly = true },
	value = {
		set = function(self, value)
			assert(type(value) == "string", "expected value to be a sting")
			local childNodes = self.__prop_values.childNodes
			if childNodes[1] then
				-- TODO: what about entity references?
				-- node exists, update it, delete rest of them
				childNodes[1].data = value
				for i = 2, #childNodes do
					childNodes[i].__prop_values.parentNode = nil
					childNodes[i] = nil
				end
			else
				-- create a new node
				childNodes[1] = Text {
					parentNode = self,
					ownerDocument = self.__prop_values.ownerDocument,
					data = value,
				}
			end
		end,
		get = function(self)
			local childNodes = self.__prop_values.childNodes
			if #childNodes == 1 then
				return childNodes[1].data
			end

			local r = {}
			for i, child in ipairs(childNodes) do
				-- TODO: what about entity references?
				r[#r+1] = child.__prop_values.data
			end

			return table.concat(r)
		end
	},
	nodeValue = {
		readonly = true,
		-- getter; see below
	},
	ownerElement = { readonly = true },
}
-- copy getter function
properties.nodeValue.get = properties.value.get


local methods = {}
function methods:__init()
	self.__prop_values.nodeType = TYPES.ATTRIBUTE_NODE

	return Node.__init(self)
end

--- exports the XML.
-- This will only write the attribute itself, any required namespace definitions
-- will be dealt with by the `Element` class.
-- @name Attribute:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	-- defining any namespaces will be dealt with on the element level
	buffer[#buffer+1] = " "..self.__prop_values.name..'="'

	local childNodes = self.__prop_values.childNodes
	for i, child in ipairs(childNodes) do
		child:write(buffer)
	end

	buffer[#buffer+1] = '"'
	return buffer
end


-- no tail call in case of errors/stacktraces
local Attribute = Class("Attribute", Node, methods, properties)
return Attribute
