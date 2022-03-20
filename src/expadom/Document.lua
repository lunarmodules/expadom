--- XML DOM Document Interface.
--
-- See the [Document](https://www.w3.org/TR/DOM-Level-2-Core/#core-i-Document)
-- and [Node](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247) interfaces.
--
-- @classmod Document

local Class = require "expadom.class"
local Node = require "expadom.Node"
local DocumentFragment = require "expadom.DocumentFragment"
local Element = require "expadom.Element"
local Attribute = require "expadom.Attr"
local NodeList = require "expadom.NodeList"
local Comment = require "expadom.Comment"
local Text = require "expadom.Text"
local CDATASection = require "expadom.CDATASection"
local ProcessingInstruction = require "expadom.ProcessingInstruction"

local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
local TYPES = constants.NODE_TYPES



--- Properties of the `Document` class, beyond the `Node` class
-- @field doctype the `DocumentType` associated with this Document (readonly)
-- @field implementation the `DOMImplementation` from which the Document was created (readonly)
-- @field documentElement the root `Element` object of the Document (readonly)
-- @table properties
local properties = {
	doctype = { readonly = true },
	implementation = { readonly = true },
	documentElement = {
		readonly = true,
		get = function(self)
			local childNodes = self.__prop_values.childNodes
			for i, child in ipairs(childNodes) do
				if child.__prop_values.nodeType == TYPES.ELEMENT_NODE then
					return child
				end
			end
		end,
	},
}



local methods = {}

function methods:__init()
	self.__prop_values.nodeType = TYPES.DOCUMENT_NODE

	local ok, err = Node.__init(self)
	if not ok then
		return ok, err
	end

	self.__prop_values.nodeName = "#document"
	return true
end


--- exports the XML.
-- @name Document:write
-- @tparam[opt] array buffer an array to which the chunks can be added.
-- @tparam[opt] table namespacesInScope namespaceURIs indexed by prefix. For any namespace
-- not in this table, the definitions will be generated.
-- @return the buffer array
function methods:write(buffer, namespacesInScope)
	buffer = buffer or {}
	namespacesInScope =  namespacesInScope or {}

	buffer[#buffer+1] = '<?xml version="1.0" encoding="UTF-8" ?>\n'
	local childNodes = self.__prop_values.childNodes
	for _, child in ipairs(childNodes) do
		child:write(buffer, namespacesInScope)
		buffer[#buffer+1] = "\n"
	end
	return buffer
end



-- Node overrides

do
	local function check(self, newChild)
		-- docs can have max 1 elem, and 1 doctype, let's count...
		local newType = newChild.__prop_values.nodeType
		local lst
		if newType == TYPES.DOCUMENT_FRAGMENT_NODE then
			lst = newChild.childNodes
		else
			lst = { newChild }
		end

		local elem = self.documentElement and 1 or 0
		local doctype = 1 -- read-only, so set or not, always start at 1

		for i, node in ipairs(lst) do
			local t = node.__prop_values.nodeType
			if t == TYPES.ELEMENT_NODE then
				elem = elem + 1
			elseif t == TYPES.DOCUMENT_TYPE_NODE then
				doctype = doctype + 1
			end
		end

		if elem > 1 or doctype > 1 then
			return nil, ERRORS.INVALID_MODIFICATION_ERR
		end
		return true
	end


	function methods:appendChild(newChild)
		local ok, err = check(self, newChild)
		if not ok then
			return nil, err
		end

		return Node.appendChild(self, newChild)
	end


	function methods:insertBefore(newChild, refChild)
		local ok, err = check(self, newChild)
		if not ok then
			return nil, err
		end

		return Node.insertBefore(self, newChild, refChild)
	end
end


function methods:removeChild(oldChild)
	local oldType = oldChild.__prop_values.nodeType
	if oldType == TYPES.DOCUMENT_TYPE_NODE then
		-- cannot change docType
		return nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
	end

	return Node.removeChild(self, oldChild)
end


function methods:replaceChild(newChild, oldChild)
	if oldChild == nil then
		return nil, ERRORS.NOT_FOUND_ERR
	end
	if newChild == oldChild then
		return oldChild
	end

	local newType = newChild.__prop_values.nodeType
	local oldType = oldChild.__prop_values.nodeType

	if newType == TYPES.ELEMENT_NODE then
		if oldType ~= TYPES.ELEMENT_NODE and
			self.documentElement ~= nil then
			-- adding a new element can only be done if we're replacing the
			-- existing element, or if no element has been set yet.
			return nil, ERRORS.INVALID_MODIFICATION_ERR
		end

	elseif newType == TYPES.DOCUMENT_TYPE_NODE or
		oldType == TYPES.DOCUMENT_TYPE_NODE then
		-- cannot change docType
		return nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
	end

	-- replacing wil first insert the new one, then remove the old one
	-- this fails if they both are Elements. Hence we temporarily change
	-- the new type to a comment to make it succeed.
	newChild.__prop_values.nodeType = TYPES.COMMENT_NODE
	local ok, err = Node.replaceChild(self, newChild, oldChild)
	newChild.__prop_values.nodeType = newType

	return ok, err
end



-- Document interface


--- Creates a plain `Attribute` node, implements [createAttribute](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1084891198).
-- @tparam string name attribute name.
-- @name Document:createAttribute
-- @return new `Attribute` node
function methods:createAttribute(name)
	return Attribute {
		ownerDocument = self,
		name = name,
	}
end


--- Creates a namespaced `Attribute` node, implements [createAttributeNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-DocCrAttrNS).
-- @tparam string namespaceURI the namespaceURI for the Attribute.
-- @tparam string qualifiedName the qualified attribute name.
-- @name Document:createAttributeNS
-- @return new `Attribute` node
function methods:createAttributeNS(namespaceURI, qualifiedName)
	return Attribute {
		ownerDocument = self,
		qualifiedName = qualifiedName,
		namespaceURI = namespaceURI,
	}
end


--- Creates a `CDATASection` node, implements [createCDATASection](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-D26C0AF8).
-- @tparam string data the CData contents.
-- @name Document:createCDATASection
-- @return new `CDATASection` node
function methods:createCDATASection(data)
	return CDATASection {
		ownerDocument = self,
		data = data,
	}
end


--- Creates a `Comment` node, implements [createComment](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1334481328).
-- @tparam string data the comment.
-- @name Document:createComment
-- @return new `Comment` node
function methods:createComment(data)
	return Comment {
		ownerDocument = self,
		data = data,
	}
end


--- Creates a `DocumentFragment` node, implements [createDocumentFragment](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-35CB04B5).
-- @name Document:createDocumentFragment
-- @return new `DocumentFragment` node
function methods:createDocumentFragment()
	return DocumentFragment { ownerDocument = self }
end


--- Creates a `Element` node, implements [createElement](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-2141741547).
-- @tparam string tagName the tagname for the new `Element`.
-- @name Document:createElement
-- @return new `Element` node
function methods:createElement(tagName)
	return Element {
		ownerDocument = self,
		tagName = tagName,
	}
end


--- Creates a namespaced `Element` node, implements [createElementNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-DocCrElNS).
-- @tparam string namespaceURI the namespaceURI for the Element.
-- @tparam string qualifiedName the qualified element name.
-- @name Document:createElementNS
-- @return new `Element` node
function methods:createElementNS(namespaceURI, qualifiedName)
	return Element {
		ownerDocument = self,
		qualifiedName = qualifiedName,
		namespaceURI = namespaceURI,
	}
end


--- Not implemeneted. Creates a `EntityReference` node, implements [createEntityReference](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-392B75AE).
-- @tparam string name the entity reference name.
-- @name Document:createEntityReference
-- @return new `EntityReference` node
function methods:createEntityReference(name)
	error("--TODO: implement createEntityReference")
end


--- Creates a `ProcessingInstruction` node, implements [createProcessingInstruction](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-135944439).
-- @tparam string target the target for the instruction.
-- @tparam string data the instruction.
-- @name Document:createProcessingInstruction
-- @return new `ProcessingInstruction` node
function methods:createProcessingInstruction(target, data)
	return ProcessingInstruction {
		ownerDocument = self,
		target = target,
		data = data,
	}
end


--- Creates a `Text` node, implements [createTextNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1975348127).
-- @tparam string data the contents of the new `Text` node.
-- @name Document:createTextNode
-- @return new `Text` node
function methods:createTextNode(data)
	return Text {
		ownerDocument = self,
		data = data,
	}
end

--- Not implemented. Returns a child matching the name, implements [getElementById](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-getElBId).
-- @tparam string elementId the `id` value to search for.
-- @name Document:getElementById
-- @return the matching `Element` node
function methods:getElementById(elementId)
	-- from the DOM level 2 spec: Implementations that do not know whether
	-- attributes are of type ID or not are expected to return null.
	return nil
end


--- Returns a list of children matching the name, implements [getElementsByTagName](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-A6C9094).
-- The search is done recursively over the full depth, in a preorder traversal,
-- and this will be the order of the elements in the returned `NodeList`.
-- @tparam string name `Element` tag name to search for, or `"*"` to match all.
-- @name Document:getElementsByTagName
-- @return `NodeList` with children with the requested name.
function methods:getElementsByTagName(tagname)
	local list = NodeList()
	local root = self.documentElement
	if root then
		-- call method using dot-notation, and pass in document as 'self', to
		-- ensure root-element itself is included in the traversal
		root._getElementsByTagName(self, tagname, list)
	end
	return list
end


--- Returns a list of children matching the namespace, implements [getElementsByTagNameNS](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-getElBTNNS).
-- The search is done recursively over the full depth, in a preorder traversal,
-- and this will be the order of the elements in the returned `NodeList`.
-- @tparam string namespaceURI `Element` namespace URI to search for, or `"*"` to match all.
-- @tparam string localName `Element` localname to search for, or `"*"` to match all.
-- @name Document:getElementsByTagNameNS
-- @return `NodeList` with children with the requested namespace.
function methods:getElementsByTagNameNS(namespaceURI, localName)
	local list = NodeList()
	local root = self.documentElement
	if root then
		-- call method using dot-notation, and pass in document as 'self', to
		-- ensure root-element itself is included in the traversal
		root._getElementsByTagNameNS(self, namespaceURI, localName, list)
	end
	return list
end


--- Not implemented. Clones and imports the node, implements [importNode](https://www.w3.org/TR/DOM-Level-2-Core/#core-Core-Document-importNode).
-- @tparam Node importedNode the `Node` to import from another `Document`.
-- @tparam bool deep if `true` create a recursive copy.
-- @name Node:importNode
-- @return the newly cloned and imported `Node`, or nil+err
function methods:importNode(importedNode, deep)
	error("--TODO: implement importNode")
end


-- no tail call in case of errors/stacktraces
local Document = Class("Document", Node, methods, properties)
return Document
