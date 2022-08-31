--- XML DOM DOMImplementation class.
--
-- See the [DOMImplementation interface](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-102161490)
--
-- @classmod DOMImplementation

local Class = require "expadom.class"
local DocumentType = require "expadom.DocumentType"
local Document = require "expadom.Document"
local Node = require "expadom.Node"
local Element = require "expadom.Element"
local xmlutils = require "expadom.xmlutils"
local constants = require "expadom.constants"
local ERRORS = constants.ERRORS


local methods = {}


--- Not implemented.
function methods:hasFeature(feature, version)
	-- TODO: implement hasFeature
	error("not implemented")
end



--- Creates a new Document instance, implements [createDocument](https://www.w3.org/TR/DOM-Level-2-Core/#core-Level-2-Core-DOM-createDocument).
-- In addition to the Core spec, it also returns a second return value, the `documentElement` created.
-- @tparam string|nil namespaceURI (required if the `qualifiedName` has a prefix)
-- @tparam string qualifiedName the `tagName` of the top element, can have a prefix.
-- @tparam[opt] DocumentType doctype a DocumentType instance.
-- @return a new Document instance + the `documentElement`
-- @usage
-- local DOM = require("expadom.DOMImplementation")()  -- create an instance
-- local doc1, root1 = DOM:createDocument(nil, "root")                       -- plain root element
-- local doc2, root2 = DOM:createDocument("http://namespace", "prefix:root") -- namespaced root element
-- local doc3, root3 = DOM:createDocument("http://namespace", "root")        -- root element with default namespace
function methods:createDocument(namespaceURI, qualifiedName, doctype)
	if doctype ~= nil then
		if not Class.is_instance_of(DocumentType, doctype) then
			return nil, "expected docType object"
		end
		if doctype.ownerDocument ~= nil then
			return nil, ERRORS.WRONG_DOCUMENT_ERR
		end
	end

	local doc = Document {
		doctype = doctype,
		implementation = self,
	}

	if doctype then -- DocType added first
		doctype.__prop_values.ownerDocument = doc
		-- doc will not allow modifying doctypes, so skip and call
		-- ancestor Node to insert it
		Node.appendChild(doc, doctype)
	end

	-- root element to be added AFTER doctype
	local root_elem, err = Element {
		ownerDocument = doc,
		namespaceURI = namespaceURI,
		qualifiedName = qualifiedName,
	}
	if not root_elem then
		return nil, err
	end

	doc:appendChild(root_elem)
	return doc, root_elem
end



--- Creates a new DocumentType instance, implements [createDocumentType](https://www.w3.org/TR/DOM-Level-2-Core/#core-Level-2-Core-DOM-createDocType).
-- @tparam string qualifiedName the DocumentType name
-- @tparam string publicId the public id
-- @tparam string systemId the system id
-- @return a new DocumentType instance
function methods:createDocumentType(qualifiedName, publicId, systemId)
	local localname, prefix = xmlutils.validate_qualifiedname(qualifiedName)
	if not localname then
		return nil, prefix
	end
	if (publicId ~= nil and type(publicId) ~= "string") or
		(systemId ~= nil and type(systemId) ~= "string") then
		return nil, ERRORS.INVALID_CHARACTER_ERR
	end

	local doctype = DocumentType {
		publicId = publicId,
		systemId = systemId,
		name = qualifiedName,
		prefix = prefix,
		localName = localname,
	}

	return doctype
end




-- no tail call in case of errors/stacktraces
local DOMImplementation = Class("DOMImplementation", nil, methods)
return DOMImplementation
