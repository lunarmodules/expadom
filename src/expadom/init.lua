--- expadom parser.
--
-- This parser is build on LuaExpat and parses a document (as a whole or in chunks)
-- into the DOM structure.
-- @module expadom

local lxp = require "lxp"
local DOM = require("expadom.DOMImplementation")()
local constants = require "expadom.constants"
local TYPES = constants.NODE_TYPES


local SEPARATOR = "?"--"\1"
local DEFAULT_NS_KEY = constants.DEFAULT_NS_KEY

local M = {}

-- splits a triplet name into its qualifiedName and namespace.
-- @return qualifiedName, namespaceUri (latter can be nil)
local function split(name)
	local first, second
	first = name:find(SEPARATOR, 1, true)
	if not first then
		return name
	end
	second = name:find(SEPARATOR, first+1, true)
	if not second then
		return name:sub(first+1, -1), name:sub(1, first-1)
	end
	return name:sub(second+1, -1) .. ":" .. name:sub(first+1, second-1), name:sub(1, first-1)
end



-- PARSER


do
	local context_cache = setmetatable({}, { __mode = "k" })

	local callbacks = {
		-- doc declaration
		XmlDecl = function(parser, version, encoding, standalone)
			local doc = context_cache[parser].doc
			doc.xmlVersion = version
			doc.xmlStandalone = standalone
			doc.__prop_values.inputEncoding = encoding
		end,

		-- document type declaration
		StartDoctypeDecl = function(parser, name, sysid, pubid, has_internal_subset)
			local ctx = context_cache[parser]
			local dtd = DOM:createDocumentType(name, pubid, sysid)
			if has_internal_subset then
				-- TODO: set an actual internal subset, for now only a non-nil empty string
				dtd.__prop_values.internalSubset = ""
			end

			-- since we cannot add the DTD after creating the doc itself,
			-- we temporarily change the type, insert it, and change type back
			-- when we insert the root element
			ctx.dtd = dtd
			dtd.__prop_values.nodeType = TYPES.COMMENT_NODE
			assert(ctx.doc:appendChild(dtd))

			ctx.node = dtd
		end,

		ElementDecl = function(parser, name, type, quantifier, children)
			-- local dtd = context_cache[parser].dtd
			-- dtd[#dtd+1] = {
			-- 	cb = "ElementDecl",
			-- 	name = name,
			-- 	type = type,
			-- 	quantifier = quantifier,
			-- 	children = children,
			-- }
		end,

		AttlistDecl = function(parser, elementName, attrName, attrType, default, required)
			-- local dtd = context_cache[parser].dtd
		end,

		EntityDecl = function(parser, entityName, is_parameter, value, base, systemId, publicId, notationName)
			-- local ctx = context_cache[parser]
		end,

		ExternalEntityRef = function(parser, subparser, base, systemId, publicId)
			-- local ctx = context_cache[parser]
		end,

		NotationDecl = function(parser, notationName, base, systemId, publicId)
			-- local dtd = context_cache[parser].dtd
		end,

		ProcessingInstruction = function(parser, target, data)
			local ctx = context_cache[parser]
			local pi = ctx.doc:createProcessingInstruction(target, data)
			assert(ctx.node:appendChild(pi))
		end,

		EndDoctypeDecl = function(parser)
			local ctx = context_cache[parser]
			ctx.node = ctx.doc
		end,

		CharacterData = function(parser, data)
			local ctx = context_cache[parser]
			local node = ctx.node
			local nodeType = node.nodeType
			if nodeType == TYPES.CDATA_SECTION_NODE then
				node:appendData(data)
			elseif nodeType == TYPES.ELEMENT_NODE then
				local last = node.lastChild
				if last and last.nodeType == TYPES.TEXT_NODE then
					-- append to existing text node
					last:appendData(data)
				else
					-- insert new text node
					assert(node:appendChild(
						assert(ctx.doc:createTextNode(data))
					))
				end
			else
				error("catch all: is to go somewhere else")
			end
		end,

		Comment = function(parser, data)
			local ctx = context_cache[parser]
			local comment = ctx.doc:createComment(data)
			assert(ctx.node:appendChild(comment))
		end,

		-- Default = function(parser, data)
		-- 	local ctx = context_cache[parser]
		-- end,

		-- DefaultExpand = function(parser, data) -- overrides "Default" if set
		-- 	local ctx = context_cache[parser]
		-- end,

		StartCdataSection = function(parser)
			local ctx = context_cache[parser]
			local cdata = ctx.doc:createCDATASection("")
			assert(ctx.node:appendChild(cdata))
			ctx.node = cdata
		end,

		EndCdataSection = function(parser)
			local ctx = context_cache[parser]
			ctx.node = ctx.node.parentNode
		end,

		-- NotStandalone = function(parser)
		-- 	local ctx = context_cache[parser]
		-- end,

		StartElement = function(parser, elementName, attributes)
			local ctx = context_cache[parser]
			local doc = ctx.doc
			local qualifiedName, namespaceURI = split(elementName)

			-- attach defined explicit namespaces on this element
			local explicitNamespaces = ctx.explicitNamespaces
			ctx.explicitNamespaces = {}


			local elem
			if namespaceURI then
				elem = assert(doc:createElementNS(namespaceURI, qualifiedName))
				local prefix = elem.__prop_values.prefix
				explicitNamespaces[prefix or DEFAULT_NS_KEY] = nil -- remove since it's implicit
			else
				elem = assert(doc:createElement(qualifiedName))
			end

			-- add attributes
			-- TODO: deal with default attributes
			for i, attrName in ipairs(attributes) do
				local attrValue = attributes[attrName]
				local qualifiedName, namespaceURI = split(attrName)

				if namespaceURI then
					local attr = assert(elem:setAttributeNS(namespaceURI, qualifiedName, attrValue))
					explicitNamespaces[attr.__prop_values.prefix] = nil -- remove since it's implicit
				else
					assert(elem:setAttribute(qualifiedName, attrValue))
				end
			end

			-- add remaining namespace definitions as attributes
			for prefix, namespaceURI in pairs(explicitNamespaces) do
				assert(elem:defineNamespace(namespaceURI, prefix))
			end

			if ctx.node == doc then
				-- root node, so replace temporary one
				doc:replaceChild(elem, doc.documentElement)
				local children = doc.childNodes
				-- move any other nodes in front of the root-element to get
				-- the root one in the proper position
				for i = 2, #children do  -- #1 is the root element
					doc:insertBefore(children[i], elem)
				end

				-- update dtd to original type again; temporary changed to comment
				-- when added
				if ctx.dtd then
					ctx.dtd.__prop_values.nodeType = TYPES.DOCUMENT_TYPE_NODE
					ctx.dtd = nil
				end

			else
				assert(ctx.node:appendChild(elem))
			end
			ctx.node = elem
		end,

		EndElement = function(parser, elementName)
			local ctx = context_cache[parser]
			ctx.node = ctx.node.parentNode
		end,

		StartNamespaceDecl = function(parser, prefix, namespaceUri)
			local ctx = context_cache[parser]
			-- add to list of explicitly defined namespaces, implicit namespaces
			-- will be removed when adding elements/attributes, so only the ones
			-- that would otherwise be lost will remain.
			-- Default namespace is always explicit.
			ctx.explicitNamespaces[prefix or DEFAULT_NS_KEY] = namespaceUri
		end,

		EndNamespaceDecl = function(parser, namespaceName)
			-- local ctx = context_cache[parser]
			-- print("end: ",tostring(namespaceName))
		end,

	}


	--- Creates a new parser and accompanying DOM document.
	-- This can be used to parse a document in chunks, otherwise use `parseDocument`
	-- as it is more convenient.
	-- The document will have a temporary root-element to start with, but that
	-- one will be replaced with the actual parsed one during parsing.
	-- @return parser (a LuaExpat parser object) + DOM document (empty to start with)
	-- @usage
	-- local parser = expadom.createParser()
	-- for _, chunk in ipairs(chunks) do
	--   local a,b,c,d,e = parser:parse(chunk1)
	--   if not a then
	--     parser:close(parser)
	--     return a,b,c,d,e
	--   end
	-- end
	--
	-- local doc,b,c,d,e = expadom.closeParser(parser)
	-- if not doc then
	--   return doc, a,b,c,d,e
	-- end
	--
	-- -- 'doc' contains the xml document
	function M.createParser()
		local doc = DOM:createDocument(nil, "temp") -- creates a temporary root node
		local context = {
			doc = doc,
			explicitNamespaces = {},
			node = doc,		-- the current node
		}
		local parser = lxp.new(callbacks, SEPARATOR):returnnstriplet(true)
		context_cache[parser] = context
		return parser, doc
	end

	--- Returns the document for a parser.
	-- @param parser A parser created by `createParser`.
	-- @return a DOM document to which the parser will add.
	function M.getParserDocument(parser)
		return context_cache[parser]
	end

	--- Closes the parser and returns the parsed document.
	-- @param parser A parser created by `createParser`.
	-- @return a complete parsed DOM document, or nil+err.
	function M.closeParser(parser)
		local a,b,c,d,e = parser:parse()
		parser:close()
		if not a then
			context_cache[parser] = nil
			return a,b,c,d,e
		end
		local doc = context_cache[parser].doc
		context_cache[parser] = nil
		return doc
	end

	--- Parses an XML document into a DOM model.
	-- This method is easy to use if you have the full document already, and don't
	-- need to parse in chunks.
	-- @tparam string data the input text to parse (complete XML document)
	-- @return the Document object parsed, or nil+parse-error
	function M.parseDocument(data)
		local parser = M.createParser()
		local a,b,c,d,e = parser:parse(data)
		if not a then
			parser:close()
			context_cache[parser] = nil
			return a,b,c,d,e
		end
		return M.closeParser(parser)
	end

end

return M
