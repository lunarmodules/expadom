--- XML DOM Text Interface.
--
-- See the [Text](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1312295772)
-- the [CharacterData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-FF21A306),
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod Text

local Class = require "expadom.class"
local CharacterData = require "expadom.CharacterData"

local utf8 = require("expadom.xmlutils").utf8
local escape = require("expadom.xmlutils").escape
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES


local properties = {
}

local methods = {}

function methods:__init()
	local ok, err = CharacterData.__init(self)
	if not ok then
		return ok, err
	end

	self.__prop_values.nodeType = TYPES.TEXT_NODE
	self.__prop_values.nodeName = "#text"

	return true
end


--- exports the XML.
-- @name Text:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	buffer[#buffer+1] = escape(self.__prop_values.data)
	return buffer
end


--- Splits a text node, implements [splitText](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-32791A2F).
-- Indices 1-indexed, and based on UTF-8 characters, not bytes.
-- @name Text:splitText
-- @tparam int offset start character
-- @return the new node, or nil+err
function methods:splitText(offset)
	local len = self.__prop_values.length
	local data = self.__prop_values.data
	if offset > (len+1) or offset < 1 then
		return nil, ERRORS.INDEX_SIZE_ERR
	end

	offset = utf8.offset(data, offset)
	self.data = data:sub(1, offset-1)
	local newNode = self.ownerDocument:createTextNode(data:sub(offset, -1))
	local parent = self.__prop_values.parentNode
	if parent then
		-- we have a parent, go insert the new node
		local nextNode = self.nextSibling
		if nextNode then
			parent:insertBefore(newNode, nextNode)
		else
			-- no next child, so it was the last node; append
			parent:appendChild(newNode)
		end
	end
	return newNode
end


-- no tail call in case of errors/stacktraces
local Text = Class("Text", CharacterData, methods, properties)
return Text
