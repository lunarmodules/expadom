--- XML DOM Element Interface.
--
-- See the [Element](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-745549614)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod Element


local Class = require "expadom.class"
local Node = require "expadom.Node"
local NodeList = require "expadom.NodeList"
local NamedNodeMap = require "expadom.NamedNodeMap"

local xmlutils = require "expadom.xmlutils"
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES
local format = string.format
local escape = xmlutils.escape
local DEFAULT_NS_KEY = constants.DEFAULT_NS_KEY
local NIL_SENTINEL = constants.NIL_SENTINEL


--- Properties of the `Element` class, beyond the `Node` class
-- @field tagName (string) the tag name for the element (readonly)
-- @field explicitNamespaces (table) a table holding namespace-URIs indexed by prefix
-- (or `constants.DEFAULT_NS_KEY` for the default namespace). This is additional to the
-- DOM2 spec, and will be used when calling `write`.
-- @table properties
local properties = {
	tagName = { readonly = true },

	-- Non DOM2 property
	explicitNamespaces = { readonly = true },
}


local methods = {}
function methods:__init()
	self.__prop_values.nodeType = TYPES.ELEMENT_NODE

	local ok, err = Node.__init(self)
	if not ok then
		return ok, err
	end

	self.__prop_values.attributes = NamedNodeMap { parentNode = self }
	self.__prop_values.explicitNamespaces = {}
	return true
end


do
	local function writeNamespace(buffer, prefix, namespaceURI, namespacesInScope, revertNamespaces)
		local prefix = prefix or DEFAULT_NS_KEY
		if namespacesInScope[prefix] == namespaceURI then
			return  -- prefix+namespace is already in scope, nothing to do
		end

		if revertNamespaces[prefix] then
			-- same prefix on element and/or attributes points to different URI
			error(format("prefix '%s' has 2 URIs defined on the same element; '%s' and '%s'", prefix,
				namespacesInScope[prefix], namespaceURI))
		end

		-- book keeping
		revertNamespaces[prefix] = namespacesInScope[prefix] or NIL_SENTINEL
		namespacesInScope[prefix] = namespaceURI

		-- write namespace definition
		if prefix == DEFAULT_NS_KEY then
			buffer[#buffer+1] = ' xmlns="'..escape(namespaceURI)..'"'
		else
			buffer[#buffer+1] = ' xmlns:'..prefix..'="'..escape(namespaceURI)..'"'
		end
	end

	--- exports the XML.
	--
	-- Writing namespaces:
	--
	-- * Namespaces set in the `namespacesInScope` table will be assumed to have already
	-- been defined and no declarations for those will be generated.
	--
	-- * Namespaces in use in this `Element` or any of its `Attribute`s will implicitly
	-- be defined on the `Element` unless they are already in scope.
	--
	-- * Namespaces set in the `Element.explicitNamespaces` table will be defined on this
	-- `Element` (if not already in scope). This allows to define a namespace on
	-- a higher level element (where it is not necessarily in use), to prevent many
	-- duplicate definitions further down the tree.
	--
	-- @name Element:write
	-- @tparam array buffer an array to which the chunks can be added.
	-- @tparam table namespacesInScope list of namespace URIs indexed by prefix
	-- (or `constants.DEFAULT_NS_KEY` for the default namespace).
	-- @return the buffer array
	function methods:write(buffer, namespacesInScope)
		local nodeName = self.__prop_values.nodeName
		buffer[#buffer+1] = "<"..nodeName

		-- add namespaces
		local revertNamespaces = {}
		for prefix, namespaceURI in pairs(self.__prop_values.explicitNamespaces) do
			writeNamespace(buffer, prefix, namespaceURI, namespacesInScope, revertNamespaces)
		end
		local namespaceURI = self.__prop_values.namespaceURI
		if namespaceURI then
			writeNamespace(buffer, self.__prop_values.prefix, namespaceURI, namespacesInScope, revertNamespaces)
		end

		-- add attributes
		local attributes = self.__prop_values.attributes
		if attributes then
			for i = 1, attributes.n do
				local attribute = attributes[i]
				local namespaceURI = attribute.__prop_values.namespaceURI
				if namespaceURI then
					writeNamespace(buffer, attribute.__prop_values.prefix, namespaceURI, namespacesInScope, revertNamespaces)
				end
				attribute:write(buffer, namespacesInScope)
			end
		end

		-- add children
		local children = self.__prop_values.childNodes
		if #children == 0 then
			buffer[#buffer+1] = "/>"
		else
			buffer[#buffer+1] = ">"
			for _, child in ipairs(children) do
				child:write(buffer, namespacesInScope)
			end
			buffer[#buffer+1] = "</" .. nodeName .. ">"
		end

		-- revert namespace definitions
		for prefix, namespaceURI in pairs(revertNamespaces) do
			namespacesInScope[prefix] = namespaceURI ~= NIL_SENTINEL and namespaceURI or nil
		end

		return buffer
	end
end

--- Creates or modifies a plain `Attribute` node on the Element, implements [setAttribute](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-F68F082).
-- If the `Attribute` doesn't exist yet on the `Element`, it will be created.
-- @tparam string name attribute name.
-- @tparam string value attribute value.
-- @name Element:setAttribute
-- @return created/updated `Attribute` node (this differs from the DOM2 spec)
function methods:setAttribute(name, value)
	local attribs = self.__prop_values.attributes
	local attr = attribs:getNamedItem(name)
	if not attr then
		-- create a new attribute
		local err
		attr, err = self.ownerDocument:createAttribute(name)
		if not attr then
			return nil, err
		end
		local ok, err = attribs:setNamedItem(attr)
		if not ok then
			return nil, err
		end
		attr.__prop_values.ownerElement = self
	end

	attr.value = value
	return attr
end


--- Creates or modifies a namespaced `Attribute` node on the Element, implements [setAttributeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElSetAttrNS).
-- If the `Attribute` doesn't exist yet on the `Element`, it will be created.
-- @tparam string namespaceURI the namespaceURI for the Attribute.
-- @tparam string qualifiedName the qualified attribute name.
-- @tparam string value attribute value.
-- @name Element:setAttributeNS
-- @return created/updated `Attribute` node (this differs from the DOM2 spec)
function methods:setAttributeNS(namespaceURI, qualifiedName, value)
	local attribs = self.__prop_values.attributes
	local localName, prefix = xmlutils.validate_qualifiedname(qualifiedName)
	if not localName then
		return nil, prefix
	end

	local attr = attribs:getNamedItemNS(namespaceURI, localName)
	if not attr then
		-- create a new attribute
		local err
		attr, err = self.ownerDocument:createAttributeNS(namespaceURI, qualifiedName)
		if not attr then
			return nil, err
		end
		local ok, err = attribs:setNamedItemNS(attr)
		if not ok then
			return nil, err
		end
		attr.__prop_values.ownerElement = self
	end

	attr.value = value
	if prefix ~= attr.__prop_values.prefix then
		attr.prefix = prefix  -- update using setter to update other values as well
	end
	return attr
end


--- Adds or replaces a plain `Attribute` node on the Element, implements [setAttributeNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-887236154).
-- If an `Attribute` by this name already exists on the `Element`, it will be replaced.
-- @tparam Attribute newAttr `Attribute` node to add
-- @name Element:setAttributeNode
-- @return `true` or the replaced `Attribute` node, or nil+err
function methods:setAttributeNode(newAttr)
	if newAttr.namespaceURI then
		return nil, ERRORS.NAMESPACE_ERR -- should use the NS version of method
	end

	local oldAttr, err = self.__prop_values.attributes:setNamedItem(newAttr)
	if not oldAttr then
		return nil, err
	end

	if oldAttr ~= true then
		-- its the replace Node
		oldAttr.__prop_values.ownerElement = nil
	end
	newAttr.__prop_values.ownerElement = self
	return oldAttr
end


--- Adds or replaces a namespaced `Attribute` node on the Element, implements [setAttributeNodeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElSetAtNodeNS).
-- If an `Attribute` by this name already exists on the `Element`, it will be replaced.
-- @tparam Attribute newAttr `Attribute` node to add
-- @name Element:setAttributeNodeNS
-- @return `true` or the replaced `Attribute` node, or nil+err
function methods:setAttributeNodeNS(newAttr)
	local oldAttr, err = self.__prop_values.attributes:setNamedItemNS(newAttr)
	if not oldAttr then
		return nil, err
	end

	if oldAttr ~= true then
		-- its the replace Node
		oldAttr.__prop_values.ownerElement = nil
	end
	newAttr.__prop_values.ownerElement = self
	return oldAttr
end


--- Gets a plain `Attribute` value by name, implements [getAttribute](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-666EE0F9).
-- @tparam string name `Attribute` name to lookup
-- @name Element:getAttribute
-- @return value of the attribute, or nil+err
function methods:getAttribute(name)
	local attr, err = self.__prop_values.attributes:getNamedItem(name)
	if not attr then
		return nil, err
	end
	return attr.value
end


--- Gets a namespaced `Attribute` value by namespace, implements [getAttributeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElGetAttrNS).
-- @tparam string namespaceURI `Attribute` namespace URI to lookup
-- @tparam string localName `Attribute` localname to lookup
-- @name Element:getAttributeNS
-- @return value of the attribute, or nil+err
function methods:getAttributeNS(namespaceURI, localName)
	local attr, err = self.__prop_values.attributes:getNamedItemNS(namespaceURI, localName)
	if not attr then
		return nil, err
	end
	return attr.value
end


--- Gets a plain `Attribute` node by name, implements [getAttributeNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-217A91B8).
-- @tparam string name `Attribute` name to lookup
-- @name Element:getAttributeNode
-- @return the `Attribute` node, or nil+err
function methods:getAttributeNode(name)
	return self.__prop_values.attributes:getNamedItem(name)
end


--- Gets a namespaced `Attribute` node by namespace, implements [getAttributeNodeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElGetAtNodeNS).
-- @tparam string namespaceURI `Attribute` namespace URI to lookup
-- @tparam string localName `Attribute` localname to lookup
-- @name Element:getAttributeNodeNS
-- @return the `Attribute` node, or nil+err
function methods:getAttributeNodeNS(namespaceURI, localName)
	return self.__prop_values.attributes:getNamedItemNS(namespaceURI, localName)
end


--- Removes a plain `Attribute` node by name, implements [removeAttribute](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-6D6AC0F9).
-- @tparam string name `Attribute` name to remove
-- @name Element:removeAttribute
-- @return `true`, or nil+err
function methods:removeAttribute(name)
	local attr, err = self.__prop_values.attributes:removeNamedItem(name)
	if not attr and err == ERRORS.NO_MODIFICATION_ALLOWED_ERR then
		return nil, err
	end
	if attr then
		attr.__prop_values.ownerElement = nil
	end
	return true
end


--- Removes a namespaced `Attribute` node by namespace, implements [removeAttributeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElRemAtNS).
-- @tparam string namespaceURI `Attribute` namespace URI to remove
-- @tparam string localName `Attribute` localname to remove
-- @name Element:removeAttributeNS
-- @return `true`, or nil+err
function methods:removeAttributeNS(namespaceURI, localName)
	local attr, err = self.__prop_values.attributes:removeNamedItemNS(namespaceURI, localName)
	if not attr and err == ERRORS.NO_MODIFICATION_ALLOWED_ERR then
		return nil, err
	end
	if attr then
		attr.__prop_values.ownerElement = nil
	end
	return true
end


--- Removes an `Attribute` node, implements [removeAttributeNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-D589198).
-- @tparam Attribute oldAttr the `Attribute` node to remove
-- @name Element:removeAttributeNode
-- @return the removed `Attribute` node, or nil+err
function methods:removeAttributeNode(oldAttr)
	local namespaceURI = oldAttr.__prop_values.namespaceURI
	local attr, err
	if namespaceURI then
		local localName = oldAttr.__prop_values.localName
		attr, err = self.__prop_values.attributes:removeNamedItemNS(namespaceURI, localName)
	else
		local name = oldAttr.__prop_values.name
		attr, err = self.__prop_values.attributes:removeNamedItem(name)
	end
	if attr then
		attr.__prop_values.ownerElement = nil
	end
	return attr, err
end


--- Checks existence of an `Attribute` node by name, implements [hasAttribute](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-6D6AC0F9).
-- @tparam string name `Attribute` name to check
-- @name Element:hasAttribute
-- @return boolean
function methods:hasAttribute(name)
	return not not self:getAttribute(name)
end


--- Checks existence of an `Attribute` node by namespace, implements [hasAttributeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-ElRemAtNS).
-- @tparam string namespaceURI `Attribute` namespace URI to check
-- @tparam string localName `Attribute` localname to check
-- @name Element:hasAttributeNS
-- @return boolean
function methods:hasAttributeNS(namespaceURI, localName)
	return not not self:getAttributeNS(namespaceURI, localName)
end


function methods:_getElementsByTagName(name, list)
	for _, child in ipairs(self.__prop_values.childNodes) do
		local props = child.__prop_values
		if props.nodeType == TYPES.ELEMENT_NODE then
			if props.tagName == name or name == "*" then
				list[#list+1] = child
			end
			child:_getElementsByTagName(name, list)
		end
	end
	return list
end


--- Returns a list of children matching the name, implements [getElementsByTagName](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1938918D).
-- The search is done recursively over the full depth, in a preorder traversal,
-- and this will be the order of the elements in the returned `NodeList`.
-- @tparam string name `Element` tag name to search for, or `"*"` to match all.
-- @name Element:getElementsByTagName
-- @return `NodeList` with children with the requested name.
function methods:getElementsByTagName(name)
	assert(type(name) == "string", "expected name to be a string")
	return self:_getElementsByTagName(name, NodeList())
end


function methods:_getElementsByTagNameNS(namespaceURI, localName, list)
	for _, child in ipairs(self.__prop_values.childNodes) do
		local props = child.__prop_values
		if props.nodeType == TYPES.ELEMENT_NODE then
			if props.namespaceURI and
				(props.localName == localName or localName == "*") and
				(props.namespaceURI == namespaceURI or namespaceURI == "*") then
				list[#list+1] = child
			end
			child:_getElementsByTagNameNS(namespaceURI, localName, list)
		end
	end
	return list
end


--- Returns a list of children matching the namespace, implements [getElementsByTagNameNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-A6C90942).
-- The search is done recursively over the full depth, in a preorder traversal,
-- and this will be the order of the elements in the returned `NodeList`.
-- @tparam string namespaceURI `Element` namespace URI to search for, or `"*"` to match all.
-- @tparam string localName `Element` localname to search for, or `"*"` to match all.
-- @name Element:getElementsByTagNameNS
-- @return `NodeList` with children with the requested namespace.
function methods:getElementsByTagNameNS(namespaceURI, localName)
	assert(type(namespaceURI) == "string", "expected namespaceURI to be a string")
	assert(type(localName) == "string", "expected localName to be a string")
	return self:_getElementsByTagNameNS(namespaceURI, localName, NodeList())
end


-- no tail call in case of errors/stacktraces
local Element = Class("Element", Node, methods, properties)
return Element
