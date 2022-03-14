--- XML DOM ProcessingInstruction Interface.
--
-- See the [ProcessingInstruction](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1004215813)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod ProcessingInstruction

local Class = require "expadom.class"
local Node = require "expadom.Node"

local utf8 = require("expadom.xmlutils").utf8
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES


--- Properties of the `ProcessingInstruction` class, beyond the `Node` class
-- @field target (string) the target as defined in the PI (readonly)
-- @field data (string) the PI data
-- @field nodeValue (string) the PI data, same as `data` (readonly)
-- @table properties
local properties = {
	target = { readonly = true },
	data = {
		set = function(self, data)
			assert(type(data) == "string", "expected data to be a string")

			local length = utf8.len(data)
			if not length then
				error(ERRORS.INVALID_CHARACTER_ERR)
			end

			self.__prop_values.data = data
		end
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
	self.__prop_values.nodeType = TYPES.PROCESSING_INSTRUCTION_NODE

	local ok, err = Node.__init(self)
	if not ok then
		return ok, err
	end

	-- invoke setter for validation
	self.data = self.__prop_values.data

	local target = self.__prop_values.target
	assert(type(target) == "string", "expected target to be a string")
	if target:find("%s") then -- this is a pretty lame check...
		return nil, ERRORS.INVALID_CHARACTER_ERR
	end

	self.__prop_values.nodeName = target

	return true
end


--- exports the XML.
-- @name ProcessingInstruction:write
-- @tparam array buffer an array to which the chunks can be added.
-- @return the buffer array
function methods:write(buffer)
	buffer[#buffer+1] = string.format("<?%s %s?>", self.__prop_values.target, self.__prop_values.data)
	return buffer
end



-- no tail call in case of errors/stacktraces
local ProcessingInstruction = Class("ProcessingInstruction", Node, methods, properties)
return ProcessingInstruction
