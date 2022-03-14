--- XML DOM Comment AND CharacterData Interface.
--
-- The `CharacterData` does not have its own node-type in DOM2 specs, hence we
-- simply use the Comment class, since that class inherits from `CharacterData`,
-- but doesn't add anything.
--
-- `CharacterData` is not its own class/type (no type-constant defined), and since
-- a Comment type doesn't add anything to the CharacterData, we actually use
-- the Comment type also as the base for `CharacterData` derivatives such as
-- `Text` and `CDATASection`.
--
-- See the [Comment](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1728279322),
-- the [CharacterData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-FF21A306),
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod Comment


local Class = require "expadom.class"
local Node = require "expadom.Node"

local xmlutils = require "expadom.xmlutils"
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES
local utf8 = require("expadom.xmlutils").utf8


--- Properties of the `Comment` class, beyond the `Node` class
-- @field data (string) the comment data
-- @field length (int) the length of the `data` in UTF-8 characters (readonly)
-- @field nodeValue (string) same as field `data` (readonly)
-- @table properties
local properties = {
	data = {
		set = function(self, data)
			assert(type(data) == "string", "expected data to be a string")

			local length = xmlutils.utf8.len(data)
			if not length then
				error(ERRORS.INVALID_CHARACTER_ERR)
			end

			self.__prop_values.data = data
			self.__prop_values.length = length
		end
	},
	length = {
		readonly = true,
	},
	nodeValue = {
		readonly = true,
		get = function(self)
			return self.__prop_values.data
		end,
	},
}



local methods = {}

function methods:__init()
	self.__prop_values.nodeType = TYPES.COMMENT_NODE

	local ok, err = Node.__init(self)
	if not ok then
		return ok, err
	end

	-- invoke setter for validation
	self.data = self.__prop_values.data
	self.__prop_values.nodeName = "#comment"

	return true
end


--- exports the XML.
-- @name Comment:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	buffer[#buffer+1] = "<!--" .. self.__prop_values.data .. "-->"
	return buffer
end

--- Appends data, implements [appendData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-32791A2F).
-- @name CharacterData:appendData
-- @tparam string arg the data to append
-- @return nothing
function methods:appendData(arg)
	self.data = self.__prop_values.data .. arg
end


--- Deletes data, implements [deleteData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-7C603781).
-- Indices 1-indexed, and based on UTF-8 characters, not bytes.
-- @name CharacterData:deleteData
-- @tparam int offset start character
-- @tparam int count number of characters to delete
-- @return true or nil+err
function methods:deleteData(offset, count)
	local len = self.__prop_values.length
	local data = self.__prop_values.data
	if offset > len or offset < 1 or count < 0 then
		return nil, ERRORS.INDEX_SIZE_ERR
	elseif count == 0 then
		return true
	else
		if count + offset - 1 > len then
			count = len - offset + 1
		end
		local e = utf8.offset(data, offset) - 1
		local s = utf8.offset(data, offset + count)
		self.data = data:sub(1, e) .. data:sub(s, -1)
		return true
	end
end


--- Inserts data, implements [insertData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-3EDB695F).
-- Indices 1-indexed, and based on UTF-8 characters, not bytes.
-- @name CharacterData:insertData
-- @tparam int offset start character
-- @tparam string arg the data to insert
-- @return true or nil+err
function methods:insertData(offset, arg)
	local len = self.__prop_values.length
	local data = self.__prop_values.data
	if offset > len or offset < 1 then
		return nil, ERRORS.INDEX_SIZE_ERR
	end

	local e = utf8.offset(data, offset)
	self.data = data:sub(1, e - 1) ..arg.. data:sub(e, -1)
	return true
end


--- Replaces data, implements [replaceData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-E5CBA7FB).
-- Indices 1-indexed, and based on UTF-8 characters, not bytes.
-- @name CharacterData:replaceData
-- @tparam int offset start character
-- @tparam int count number of characters to delete
-- @tparam string arg the data to insert
-- @return true or nil+err
function methods:replaceData(offset, count, arg)
	local len = self.__prop_values.length
	local data = self.__prop_values.data
	if offset > len or offset < 1 or count < 0 then
		return nil, ERRORS.INDEX_SIZE_ERR
	elseif count == 0 then
		return true
	else
		if count + offset - 1 > len then
			count = len - offset + 1
		end
		local e = utf8.offset(data, offset) - 1
		local s = utf8.offset(data, offset + count)
		self.data = data:sub(1, e) ..arg.. data:sub(s, -1)
		return true
	end
end


--- Gets a substring, implements [substringData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-6531BCCF).
-- Indices 1-indexed, and based on UTF-8 characters, not bytes.
-- @name CharacterData:substringData
-- @tparam int offset start character
-- @tparam int count number of characters to return
-- @return true or nil+err
function methods:substringData(offset, count)
	local len = self.__prop_values.length
	local data = self.__prop_values.data
	if offset > len or offset < 1 or count < 0 then
		return nil, ERRORS.INDEX_SIZE_ERR
	elseif count == 0 then
		return ""
	else
		if count + offset - 1 > len then
			count = len - offset + 1
		end
		local s = utf8.offset(data, offset)
		local e = utf8.offset(data, count + 1, s) - 1
		return data:sub(s, e)
	end
end


-- no tail call in case of errors/stacktraces
local Comment = Class("Comment", Node, methods, properties)
return Comment
