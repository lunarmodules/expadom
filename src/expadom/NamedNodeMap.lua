--- XML DOM NamedNodeMap class.
-- Index is kept in array part of the object, names in a separate table.
--
-- Note: the `item` method returns based on 1-indexed!
--
-- Use the methods only to change, to keep the two in-sync. For faster iteration
-- use the Lua-array.
--
-- This class is used for the `attributes` property of an `Element` node. As well
-- as for 'entities' and 'notations' properties on the `DocumentType` node.
--
-- See the [NamedNodeMap](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1780488922)
-- interface.
--
-- @classmod NamedNodeMap

local Class = require "expadom.class"
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES

local EMPTY = {}
local NS_SEPARATOR = "\1"


--- Properties of the `NamedNodeMap` class
-- @field length the number of items in the `NamedNodeMap` (readonly)
-- @field parentNode the parent `Node` to which this `NamedNodeMap` belongs, additional to the DOM2 spec (readonly)
-- @table properties
local properties = {
	length = {
		readonly = true,
		get = function(self)
			return self.n
		end
	},
	-- properties not in DOM spec
	parentNode = { readonly = true },
	readonly = { readonly = true },
}


local methods = {}



function methods:__init()
	assert(self.__prop_values.parentNode, "parentNode is required")
	self.n = 0
	self.map = {}
	return true
end



--- Returns an item by name, implements [getNamedItem](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1074577549).
-- @name NamedNodeMap:getNamedItem
-- @tparam string name the name of the item to return
-- @return the item, nil if not found
function methods:getNamedItem(name)
	return self.map[name or EMPTY]
end



--- Returns an item by name and namespaceURI, implements [getNamedItem](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-getNamedItemNS).
-- @name NamedNodeMap:getNamedItemNS
-- @tparam string namespaceURI the namespace URI of the item to return
-- @tparam string name the local name of the item to return
-- @return the item, nil if not found
function methods:getNamedItemNS(namespaceURI, localName)
	return self.map[namespaceURI .. NS_SEPARATOR .. localName]
end



--- Returns item by index, implements [item](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-349467F9).
-- Indices 1-indexed.
-- @name NamedNodeMap:item
-- @tparam int idx index of item to return
-- @return the item, nil if not found
function methods:item(idx)
	return self[idx] -- non-DOM spec, but Lua  1-indexed
end



do
	local function removeNamedItem(self, name)
		if self.readonly then
			return nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
		end

		local curr_item = self.map[name]
		if not curr_item then
			return nil, ERRORS.NOT_FOUND_ERR
		end

		self.map[name] = nil
		for i, n in ipairs(self) do
			if n == curr_item then
				table.remove(self, i)
				return curr_item
			end
		end
	end


	--- Removes an item by name, implements [removeNamedItem](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-D58B193).
	-- @name NamedNodeMap:removeNamedItem
	-- @tparam string name the name of the item to return
	-- @return the item, nil+err
	function methods:removeNamedItem(name)
		return removeNamedItem(self, name)
	end


	--- Removes an item by name and namespaceURI, implements [removeNamedItemNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-removeNamedItemNS).
	-- @name NamedNodeMap:removeNamedItemNS
	-- @tparam string namespaceURI the namespace URI of the item to remove
	-- @tparam string name the local name of the item to remove
	-- @return the removed item, or nil+err
	function methods:removeNamedItemNS(namespaceURI, localName)
		return removeNamedItem(self, namespaceURI .. NS_SEPARATOR .. localName)
	end
end



do
	local function setNamedItem(self, node, name)
		if node.ownerDocument ~= (self.__prop_values.parentNode or {}).ownerDocument then
			return nil, ERRORS.WRONG_DOCUMENT_ERR
		end
		if node.nodeType == TYPES.ATTRIBUTE_NODE and node.ownerElement then
			return nil, ERRORS.INUSE_ATTRIBUTE_ERR
		end

		-- Note: we're NOT updating parentNode properties in this object.
		-- The NamedNodeMap is used for Attributes, Entities and Notations.
		-- None of those support a parentNode.
		-- Attributes have "ownerElement"

		local curr_item = self.map[name]
		if curr_item then
			-- replace existing item
			self.map[name] = node
			for i, n in ipairs(self) do
				if n == curr_item then
					self[i] = node
					return curr_item
				end
			end
		else
			-- add as new item
			local size = self.n
			size = size + 1
			self.n = size
			self[size] = node
			self.map[name] = node
			return true
		end
	end

	--- Sets an item by name, implements [removeNamedItem](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-D58B193).
	-- @name NamedNodeMap:setNamedItem
	-- @tparam Attribute|Entity|Notation arg the object to store
	-- @return the existing item or `true` if there was none, or nil+err
	function methods:setNamedItem(arg)
		return setNamedItem(self, arg, arg.nodeName)
	end

	--- Removes an item by name and namespaceURI, implements [removeNamedItemNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-removeNamedItemNS).
	-- @name NamedNodeMap:removeNamedItemNS
	-- @tparam Attribute|Entity|Notation arg the object to store
	-- @return the existing item or `true` if there was none, or nil+err
	function methods:setNamedItemNS(arg)
		return setNamedItem(self, arg, arg.namespaceURI .. NS_SEPARATOR .. arg.localName)
	end
end

-- no tail call in case of errors/stacktraces
local NamedNodeMap = Class("NamedNodeMap", nil, methods, properties)
return NamedNodeMap
