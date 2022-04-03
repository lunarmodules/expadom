--- XML DOM Node Interface.
--
-- This is the base class from which all other node types are derived.
--
-- See the [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247)
-- interface.
--
-- @classmod Node

local Class = require "expadom.class"
local NodeList = require "expadom.NodeList"
local xmlutils = require "expadom.xmlutils"
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES
local DEFAULT_NAMESPACES = constants.DEFAULT_NAMESPACES



local allowed_child_types do
	local all = {
		[TYPES.ELEMENT_NODE] 						= true,
		[TYPES.PROCESSING_INSTRUCTION_NODE] 		= true,
		[TYPES.COMMENT_NODE] 						= true,
		[TYPES.TEXT_NODE] 							= true,
		[TYPES.CDATA_SECTION_NODE] 					= true,
		[TYPES.ENTITY_REFERENCE_NODE] 				= true,
	}

	allowed_child_types= {
		[TYPES.DOCUMENT_NODE] = {
			[TYPES.ELEMENT_NODE] 					= true, -- max 1
			[TYPES.PROCESSING_INSTRUCTION_NODE] 	= true,
			[TYPES.COMMENT_NODE] 					= true,
			[TYPES.DOCUMENT_TYPE_NODE] 				= true, -- max 1
		},
		[TYPES.DOCUMENT_FRAGMENT_NODE] 			= all,
		[TYPES.DOCUMENT_TYPE_NODE] 				= nil,
		[TYPES.ENTITY_REFERENCE_NODE] 			= all,
		[TYPES.ELEMENT_NODE] 					= all,
		[TYPES.ATTRIBUTE_NODE] =  {
			[TYPES.TEXT_NODE] 						= true,
			[TYPES.ENTITY_REFERENCE_NODE] 			= true,
		},
		[TYPES.PROCESSING_INSTRUCTION_NODE] 	= nil,
		[TYPES.COMMENT_NODE] 					= nil,
		[TYPES.TEXT_NODE] 						= nil,
		[TYPES.CDATA_SECTION_NODE] 				= nil,
		[TYPES.ENTITY_NODE] 					= all,
		[TYPES.NOTATION_NODE] 					= nil,
	}
end

--- Properties of the `Node` class
-- @field attributes `NamedNodeMap` holding the associated attributes (readonly), [see per type](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1841493061)
-- @field childNodes `NodeList` holding the child nodes (readonly)
-- @field firstChild the first child `Node` (readonly)
-- @field lastChild the last child `Node` (readonly)
-- @field localName (string) the localName (readonly)
-- @field namespaceURI (string) the namespace URI (readonly)
-- @field nextSibling the next sibling child `Node` from the parent `Node` (readonly)
-- @field nodeName (string) the nodeName (readonly), [see per type](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1841493061)
-- @field nodeType the type of node, see the constant `TYPES` (readonly)
-- @field nodeValue the node value, see descendant classes (readonly), [see per type](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1841493061)
-- @field ownerDocument the `Document` object, that owns/created this node (readonly)
-- @field parentNode the `Node` object, that owns this node (readonly)
-- @field prefix (string) the namespace prefix
-- @field previousSibling the previous sibling child `Node` from the parent `Node` (readonly)
-- @field qualifiedName (string) the nodes' qualified name, additional to the DOM2 spec (readonly)
-- @field textContent the text content of this node and its descendants ([DOM level 3 property](https://www.w3.org/TR/DOM-Level-3-Core/core.html#Node3-textContent), readonly)
-- @table properties
local properties = {
	attributes = { readonly = true },
	childNodes = { readonly = true },
	firstChild = {
		readonly = true,
		get = function(self)
			return self.__prop_values.childNodes[1]
		end
	},
	lastChild = {
		readonly = true,
		get = function(self)
			local lst = self.__prop_values.childNodes
			return lst[#lst]
		end
	},
	localName = { readonly = true },
	namespaceURI = { readonly = true },
	nextSibling = {
		readonly = true,
		get = function(self)
			local p = self.__prop_values.parentNode
			if p then
				local lst = p.__prop_values.childNodes
				for i, node in ipairs(lst) do
					if node == self then
						return lst[i+1]
					end
				end
			end
		end
	},
	nodeName = { readonly = true },
	nodeType = { readonly = true },
	nodeValue = { readonly = true },	-- override in descendant Node types
	ownerDocument = {
		readonly = true,
		get = function(self)
			local doc = self.__prop_values.ownerDocument
			if doc then
				return doc	-- owning doc was already set
			end
			-- not set yet, try and get from parent
			local parent = self.parentNode
			if not parent then
				return -- no parent, so there is none
			end
			if parent.nodeType == TYPES.DOCUMENT_NODE then
				-- parent is the owning document
				doc = parent
			else
				-- get the parent here (recursing up the tree)
				doc = parent.ownerDocument
			end
			if doc then
				-- found it, store for future use
				self.__prop_values.ownerDocument = doc
			end
			return doc
		end,
	},
	parentNode = { readonly = true },
	prefix = {
		set = function(self, newPrefix)
			local props = self.__prop_values
			if not self:isNamespaced() then
				error(ERRORS.NO_MODIFICATION_ALLOWED_ERR)
			end
			if newPrefix ~= nil and type(newPrefix) ~= "string" then
				error(ERRORS.NAMESPACE_ERR)
			end
			if newPrefix == "" then
				newPrefix = nil
			end
			if newPrefix then
				assert(xmlutils.validate_prefix(newPrefix))
			end
			if newPrefix == "xml" and props.namespaceURI ~= DEFAULT_NAMESPACES.xml then
				error(ERRORS.NAMESPACE_ERR)
			end

			local localName = props.localName
			local qualifiedName = (newPrefix and (newPrefix .. ":") or "") .. localName

			if props.nodeType == TYPES.ELEMENT_NODE then
				props.tagName = qualifiedName  -- Element
			else
				if newPrefix == nil then
					error(ERRORS.NAMESPACE_ERR) -- namespaced attributes MUST have a prefix
				end
				if (qualifiedName == "xmlns" or newPrefix == "xmlns") and
					props.namespaceURI ~= DEFAULT_NAMESPACES.xmlns then
					error(ERRORS.NAMESPACE_ERR)
				end
				props.name = qualifiedName    	-- Attribute
			end
			props.prefix = newPrefix
			props.nodeName = qualifiedName
			props.qualifiedName = qualifiedName
		end
	},
	previousSibling = {
		readonly = true,
		get = function(self)
			local p = self.__prop_values.parentNode
			if p then
				local lst = p.__prop_values.childNodes
				for i, node in ipairs(lst) do
					if node == self then
						return lst[i-1]
					end
				end
			end
		end
	},
	qualifiedName = { readonly = true }, -- non DOM convenience property
	textContent = {
		readonly = true,
		get = function(self)
			error("-- TODO: implement getting textContent property")
		end,
	}
}

local methods = {}

do
	local no_parent = {
		[TYPES.ATTRIBUTE_NODE] = true,
		[TYPES.DOCUMENT_NODE] = true,
		[TYPES.DOCUMENT_FRAGMENT_NODE] = true,
		[TYPES.ENTITY_NODE] = true,
		[TYPES.NOTATION_NODE] = true,
	}

	function methods:__init()
		local props = self.__prop_values
		local nodeType = self.nodeType
		assert(nodeType, "Cannot initialize Node, no nodeType set")

		-- all Node types get a childNodes list, even if children are not allowed
		props.childNodes = NodeList()

		-- check if Node supports a parentNode
		local parentNode = props.parentNode
		if parentNode then
			assert(not no_parent[nodeType], "Node type cannot have a parent node")
		end

		-- validate names for plain and namespaced properties
		local name_prop
		if nodeType == TYPES.ELEMENT_NODE then
			name_prop = "tagName"

		elseif nodeType == TYPES.ATTRIBUTE_NODE then
			name_prop = "name"

		else
			-- Not an Element or Attribute, so we're done
			return true
		end

		-- from here only Attribute or Element nodes
		local qualifiedName, name, prefix, localName, namespaceURI = self:checkName(
				props.qualifiedName,
				props[name_prop],
				props.prefix,
				props.localName,
				props.namespaceURI,
				nodeType == TYPES.ATTRIBUTE_NODE
			)
		if not qualifiedName then
			return nil, name
		end

		props.qualifiedName = qualifiedName
		props[name_prop] = name
		props.prefix = prefix
		props.localName = localName
		props.namespaceURI = namespaceURI
		props.nodeName = qualifiedName

		return true
	end
end


--- Checks if a Node is namespaced or not.
-- This is an additional method over the DOM2 spec.
-- The node must be either an Attribute or Element type, and have a namespace.
-- @name Node:isNamespaced
-- @return boolean
function methods:isNamespaced()
	local nodeType = self.__prop_values.nodeType
	if nodeType ~= TYPES.ATTRIBUTE_NODE and nodeType ~= TYPES.ELEMENT_NODE then
		return false
	end
	-- localName is only set for namespaced attributes/elements
	return self.__prop_values.localName ~= nil
end


-- not a DOM method, check name for Attribute and Element nodes
function methods:checkName(qualifiedName, name, prefix, localName, namespaceURI, isAttr)
	if qualifiedName then
		if name or prefix or localName then
			if isAttr then
				return nil, "name, localName, and prefix must be nil if qualifiedName is given"
			end
			return nil, "tagName, localName, and prefix must be nil if qualifiedName is given"
		end

		local pos = qualifiedName:find(":")
		if not pos then
			-- has no prefix, so there MIGHT be a namespaceURI
			if namespaceURI then
				-- has a namespace so its namespaced
				localName = qualifiedName
			else
				-- not namespaced
				name = qualifiedName
			end

		else -- prefix in the qualifiedName, extract it
			prefix = qualifiedName:sub(1, pos-1)
			localName = qualifiedName:sub(pos+1, -1)
		end
	end


	if name then  -- simple DOM level 1 name
		if localName then
			if isAttr then
				return nil, "cannot specify both name and localName"
			end
			return nil, "cannot specify both tagName and localName"
		end

		if prefix or namespaceURI then
			return nil, "cannot specify namespace attributes (prefix or namespaceURI) with simple DOM level 1 name"
		end

		-- TODO: validate name

		return name, name  -- qualifiedName == name in this case, rest is nil
	end

	if not localName then
		if isAttr then
			return nil, "at least name, localName or qualifiedName must be given"
		end
		return nil, "at least tagName, localName or qualifiedName must be given"
	end

	-- TODO: validate localName

	if prefix then
		-- TODO: validate prefix

		if not namespaceURI then
			return nil, "namespaceURI is required when specifying a prefix"
		end

		if prefix == "xml" and namespaceURI ~= DEFAULT_NAMESPACES.xml then
			return nil, "prefix 'xml' is reserved for namespace '"..DEFAULT_NAMESPACES.xml.."'"
		end

		qualifiedName = prefix..":"..localName

	else
		if isAttr then
			if namespaceURI and localName ~= "xmlns" then
				return nil, "attribute must have a prefix if namespaceURI is given"
			end
			if localName == "xmlns" and namespaceURI ~= DEFAULT_NAMESPACES.xmlns then
				return nil, "attribute name 'xmlns' is reserved for namespace '"..DEFAULT_NAMESPACES.xmlns.."'"
			end
		end

		qualifiedName = localName
	end

	return qualifiedName, qualifiedName, prefix, localName, namespaceURI -- name == qualifiedName in this case
end


--- Appends a child node, implements [appendChild](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-184E7107).
-- If `newChild` is a `DocumenFragment` then all its children will be appended instead.
-- @tparam Node newChild the child `Node` to append.
-- @name Node:appendChild
-- @return newChild, or nil+err
function methods:appendChild(newChild)
	return self:insertChildAtIndex(newChild)
end


--- Clones the node, implements [cloneNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-3A0ED0A4).
-- @tparam bool deep if `true` create a recursive copy.
-- @name Node:cloneNode
-- @return newChild, or nil+err
function methods:cloneNode(deep)
	-- TODO: implement cloneNode
	error("todo implement")
end


--- Checks if the Node has attributes, implements [hasAttributes](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-NodeHasAttrs).
-- @name Node:hasAttributes
-- @return boolean
function methods:hasAttributes()
	local attr = self.__prop_values.attributes
	return attr and (#attr > 0) or false
end


--- Checks if the Node has child nodes, implements [hasChildNodes](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-810594187).
-- @name Node:hasChildNodes
-- @return boolean
function methods:hasChildNodes()
	local childNodes = self.__prop_values.childNodes
	return childNodes and (#childNodes > 0) or false
end


--- Inserts a child node, implements [insertBefore](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-952280727).
-- If `newChild` is a `DocumenFragment` then all its children will be inserted instead.
-- @tparam Node newChild the child `Node` to insert.
-- @tparam[opt] Node refChild the reference child before which `newChild` will be inserted. Defaults to appending at the end.
-- @name Node:insertBefore
-- @return newChild, or nil+err
function methods:insertBefore(newChild, refChild)
	local idx
	if refChild ~= nil then
		idx = self:nodeIndex(refChild)
		if not idx then
			return nil, ERRORS.NOT_FOUND_ERR
		end
	end

	local ok, err = self:insertChildAtIndex(newChild, idx)
	if not ok then
		return nil, err
	end

	return newChild
end


--- Not implemented, should implement [isSupported](https://www.w3.org/TR/DOM-Level-2-Core/#core-Level-2-Core-Node-supports).
-- @tparam string feature the feature to check
-- @tparam string version the version to check
-- @name Node:isSupported
-- @return throws an error for now
function methods:isSupported(feature, version)
	-- TODO: implement isSupported
	error("todo implement")
end


do
	local function combine_text(childNodes, sidx, eidx)
		-- start-index and end-index of text nodes to combine
		local data = ""
		for i = eidx, sidx+1 do -- we're deleting, so reverse traversal
			local child = childNodes[i]
			data = child.__prop_values.data .. data
			table.remove(childNodes, i)
			child.__prop_values.parentNode = nil
		end
		childNodes[sidx].data = childNodes[sidx].__prop_values.data .. data
	end

	--- Normalizes the node recursively, implements [normalize](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-normalize).
	-- Will recursively combine all adjacent `Text` nodes and remove empty `Text` nodes.
	-- @name Node:normalize
	-- @return nothing
	function methods:normalize()
		local childNodes = self.__prop_values.childNodes
		for _, child in ipairs(childNodes) do
			child:normalize()
		end

		local attribs = self.__prop_values.attributes
		if attribs then -- only Element has an attributes property
			for _, attr in ipairs(attribs) do
				attr:normalize()
			end
		end

		local eidx -- end-index of a sequence of text nodes
		-- we'll be removing nodes, so traverse in reverse order
		for i = #childNodes, 1, -1 do
			local child = childNodes[i]
			if child.__prop_values.nodeType == TYPES.TEXT_NODE then
				if #child.__prop_values.data == 0 then
					-- empty node, remove it
					table.remove(childNodes, i)
					child.__prop_values.parentNode = nil
					if eidx then
						eidx = eidx - 1
					end
				else
					if not eidx then
						eidx = i
					end
				end
			elseif eidx and (eidx - i > 1) then
				-- non-text found, but list has more than 1 text, so combine
				combine_text(childNodes, i+1, eidx)
				eidx = nil
			else
				-- only 1 text node, nothing to do, reset end index
				eidx = nil
			end
		end

		-- check if the childNodes list starts with a sequence of Text nodes
		if eidx and (eidx > 1) then
			combine_text(childNodes, 1, eidx)
		end
	end
end

--- Removes and returns a child node, implements [removeChild](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1734834066).
-- @tparam Node oldChild the child `Node` to remove.
-- @name Node:removeChild
-- @return oldChild, or nil+err
function methods:removeChild(oldChild)
	local idx, err = self:nodeIndex(oldChild)
	if not idx then
		return nil, err
	end

	oldChild.__prop_values.parentNode = nil
	table.remove(self.childNodes, idx)

	return oldChild
end


--- Removes and returns a child node, implements [replaceChild](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-785887307).
-- If `newChild` is a `DocumenFragment` then all its children will be inserted instead.
-- @tparam Node newChild the child `Node` to insert.
-- @tparam Node oldChild the child `Node` to remove.
-- @name Node:replaceChild
-- @return oldChild, or nil+err
function methods:replaceChild(newChild, oldChild)
	if oldChild == nil then
		return nil, ERRORS.NOT_FOUND_ERR
	end
	if newChild == oldChild then
		return oldChild
	end

	local ok, err = self:insertBefore(newChild, oldChild)
	if not ok then
		return nil, err
	end

	return self:removeChild(oldChild)
end



--- Recursively checks if the current node is a child of parent.
-- This is not a DOM2 method, added for convenience.
-- @tparam Node parent the Parent node to check for the child.
-- @name Node:isParent
-- @return boolean, `true` if the current Node is located somewhere in the child-tree of `parent`
function methods:isParent(parent)
	local node = self
	while node.parentNode do
		if node.parentNode == parent then
			return true
		end
		node = node.parentNode
	end
	return false
end


--- Returns the index of the child node.
-- This is not a DOM2 method, added for convenience.
-- @tparam Node child the child node to look up in the current node.
-- @name Node:nodeIndex
-- @return integer (1-indexed), or nil+err
function methods:nodeIndex(child)
	local self_doc = self.ownerDocument
	if not self_doc and self.__prop_values.nodeType == TYPES.DOCUMENT_NODE then
		self_doc = self
	end

	if child.ownerDocument ~= self_doc then
		return nil, ERRORS.WRONG_DOCUMENT_ERR
	end

	if child.__prop_values.parentNode ~= self then
		return nil, ERRORS.NOT_FOUND_ERR
	end

	for i, node in ipairs(self.__prop_values.childNodes) do
		if node == child then
			return i
		end
	end

	return nil, ERRORS.NOT_FOUND_ERR
end


--- Inserts a child node at the given index.
-- If `newChild` is a `DocumenFragment` then all its children will be inserted instead.
-- This is not a DOM2 method, added for convenience.
-- @tparam Node newChild the child node to insert.
-- @tparam[opt] int index where the child is to be inserted (defaults to appending)
-- @name Node:insertChildAtIndex
-- @return integer (1-indexed), or nil+err
function methods:insertChildAtIndex(newChild, index)
	if newChild.ownerDocument ~= self.ownerDocument and
		not (newChild.ownerDocument == self and self.nodeType == TYPES.DOCUMENT_NODE) then
		return nil, ERRORS.WRONG_DOCUMENT_ERR
	end

	local lst
	if newChild.nodeType == TYPES.DOCUMENT_FRAGMENT_NODE then
		lst = newChild.childNodes
	else
		if self:isParent(newChild) then
			return nil, ERRORS.HIERARCHY_REQUEST_ERR
		end
		lst = { newChild }
	end

	local is_allowed_type = allowed_child_types[self.nodeType]
	for i, node in ipairs(lst) do
		if not is_allowed_type[node.nodeType] then
			-- child node type is not supported in this node
			return nil, ERRORS.HIERARCHY_REQUEST_ERR
		end
	end

	local childNodes = self.childNodes
	index = index or #childNodes + 1

	--for i, node in ipairs(lst) do
	while lst[1] do
		local node = lst[1]
		local oldParent = node.__prop_values.parentNode
		if oldParent then
			if oldParent == self then
				if self:nodeIndex(node) < index then
					-- this node lives already in this list, just slightly
					-- higher up. If we remove it, our 'index' is out of sync
					-- hence we need to correct 'index' for the removal
					index = index - 1
				end
			end
			oldParent:removeChild(node)
		end
		if lst[1] == node then
			table.remove(lst, 1)
		end

		table.insert(childNodes, index, node)
		node.__prop_values.parentNode = self

		index = index + 1
	end

	return newChild
end


--- Not implemented. Checks equality, not sameness (DOM 3 method), implements [isEqualNode](https://www.w3.org/TR/DOM-Level-3-Core/core.html#Node3-isEqualNode).
-- @name Node:isEqualNode
-- @tparam Node arg the `Node` to compare with.
-- @return boolean
function methods:isEqualNode(arg)
	error("--TODO: implement isEqualNode")
end


--- Not implemented. Look up the prefix associated to the given namespace URI (DOM 3 method), implements [lookupPrefix](https://www.w3.org/TR/DOM-Level-3-Core/core.html#Node3-lookupNamespacePrefix).
-- @name Node:lookupPrefix
-- @tparam string namespaceURI the namespaceUri to lookup.
-- @return the prefix, or nil if not found
function methods:lookupPrefix(namespaceURI)
	error("--TODO: implement lookupPrefix")
end


--- Not implemented. Checks if the specified namespaceURI is the default namespace or not (DOM 3 method), implements [isDefaultNamespace](https://www.w3.org/TR/DOM-Level-3-Core/core.html#Node3-isDefaultNamespace).
-- @name Node:isDefaultNamespace
-- @tparam string namespaceURI the namespaceUri to check.
-- @return boolean
function methods:isDefaultNamespace(namespaceURI)
	error("--TODO: implement isDefaultNamespace")
end


--- Not implemented. Look up the namespace URI associated to the given prefix (DOM 3 method), implements [lookupNamespaceURI](https://www.w3.org/TR/DOM-Level-3-Core/core.html#Node3-lookupNamespaceURI).
-- @name Node:lookupNamespaceURI
-- @tparam string prefix the prefix to lookup.
-- @return the namespace URI, or nil if not found
function methods:lookupNamespaceURI(prefix)
	error("--TODO: implement lookupNamespaceURI")
end


-- no tail call in case of errors/stacktraces
local Node = Class("Node", nil, methods, properties)
return Node
