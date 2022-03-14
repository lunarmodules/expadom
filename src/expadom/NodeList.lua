--- XML DOM NodeList class.
--
-- Implemented as a standard Lua array, which is 1-indexed.
-- Note: the `item` method returns based on 1-indexed!
-- Ensure NOT to create holes.
--
-- See the [NodeList](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-536297177)
-- interface.
--
-- @classmod NodeList

local Class = require "expadom.class"



--- Properties of the `NodeList` class
-- @field length the number of items in the `NodeList` (readonly)
-- @table properties
local properties = {
	length = {
		readonly = true,
		get = function(self)
			return #self
		end
	},
}


local methods = {}

--- Returns item by index, implements [item](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-844377136).
-- Indices 1-indexed.
-- @name NodeList:item
-- @tparam int idx index of item to return
-- @return the item, nil if not found
-- @usage
-- -- this direct Lua access:
-- local itm = NodeList[1]
-- -- would be the faster version of:
-- local itm = NodeList:item(1)
function methods:item(idx)
	return self[idx]  -- non-DOM spec, but Lua  1-indexed
end


-- no tail call in case of errors/stacktraces
local NodeList = Class("NodeList", nil, methods, properties)
return NodeList
