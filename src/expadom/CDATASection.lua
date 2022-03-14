--- XML DOM CDATASection Interface.
--
-- See the [CDATASection](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-667469212)
-- the [CharacterData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-FF21A306),
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod CDATASection

local Class = require "expadom.class"
local Text = require "expadom.Text"

local constants = require "expadom.constants"
local TYPES = constants.NODE_TYPES


local properties = {}

local methods = {}

function methods:__init()
	local ok, err = Text.__init(self)
	if not ok then
		return ok, err
	end

	self.__prop_values.nodeType = TYPES.CDATA_SECTION_NODE
	self.__prop_values.nodeName = "#cdata-section"

	return true
end


--- exports the XML.
-- @name CDATASection:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	buffer[#buffer+1] = "<![CDATA[" .. self.__prop_values.data .. "]]>"
	return buffer
end


-- no tail call in case of errors/stacktraces
local CDATASection = Class("CDATASection", Text, methods, properties)
return CDATASection
