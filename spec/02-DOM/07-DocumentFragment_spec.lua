describe("DocumentFragment:", function()

	local TYPES = require("expadom.constants").NODE_TYPES
	local ERRORS = require("expadom.constants").ERRORS
	local DEFAULT_NS_KEY = require("expadom.constants").DEFAULT_NS_KEY

	local DOM = require("expadom.DOMImplementation")()
	local Node = require "expadom.Node"

	local doc
	before_each(function()
		doc = assert(DOM:createDocument("http://example.dev/some/path", "ns:root"))
	end)


	it("reports proper nodeName", function()
		local fragment = doc:createDocumentFragment()
		assert.equal("#document-fragment", fragment.nodeName)
	end)


	it("reports proper nodeValue", function()
		local fragment = doc:createDocumentFragment()
		assert.equal(nil, fragment.nodeValue)
	end)


	describe("holds other nodes,", function()

		local node_types = {
			[TYPES.ELEMENT_NODE] 						= true,
			[TYPES.PROCESSING_INSTRUCTION_NODE] 		= true,
			[TYPES.COMMENT_NODE] 						= true,
			[TYPES.TEXT_NODE] 							= true,
			[TYPES.CDATA_SECTION_NODE] 					= true,
			[TYPES.ENTITY_REFERENCE_NODE] 				= true,
			[TYPES.DOCUMENT_TYPE_NODE] 					= false,
			-- skipping fragments here; because it is never added, but the
			-- elements inside it are being added.
			--[TYPES.DOCUMENT_FRAGMENT_NODE]	 			= false,
			[TYPES.ATTRIBUTE_NODE] 						= false,
			[TYPES.ENTITY_NODE] 						= false,
			[TYPES.NOTATION_NODE] 						= false,
		}


		for t, allowed in pairs(node_types) do

			it((allowed and "allows" or "doesn't allow").." type "..tostring(t), function()
				local fragment = doc:createDocumentFragment()
				if allowed then
					local n = Node {
						nodeType = t,
						ownerDocument = doc,
						qualifiedName = "ns:name", -- only for Element
						namespaceURI = "http://ns", -- only for Element
					}
					assert(fragment:appendChild(n))
				else
					local n = Node {
						nodeType = t,
						ownerDocument = doc,
						qualifiedName = "ns:name", -- only for Attribute
						namespaceURI = "http://ns", -- only for Attribute
					}
					assert.same({
						nil, ERRORS.HIERARCHY_REQUEST_ERR
					},{
						fragment:appendChild(n)
					})
				end
			end)

		end

	end)



	describe("methods:", function()

		describe("write()", function()

			it("exports xml-snippet and returns buffer", function()
				local fragment = doc:createDocumentFragment()
				fragment:appendChild(doc:createComment("new comment"))
				fragment:appendChild(doc:createElement("plainTag"))
				fragment:appendChild(doc:createElementNS("http://ns", "defaultNamespace"))
				fragment:appendChild(doc:createElementNS("http://pref", "prefix:namespace"))
				assert.same({
					'<!--new comment-->',
					'<plainTag',
					'/>',
					'<defaultNamespace',
					' xmlns="http://ns"',
					'/>',
					'<prefix:namespace',
					' xmlns:prefix="http://pref"',
					'/>',
				}, fragment:write()) -- parameters optional
			end)


			it("skips namespace definitions if provided", function()
				local fragment = doc:createDocumentFragment()
				fragment:appendChild(doc:createComment("new comment"))
				fragment:appendChild(doc:createElement("plainTag"))
				fragment:appendChild(doc:createElementNS("http://ns", "defaultNamespace"))
				fragment:appendChild(doc:createElementNS("http://pref", "prefix:namespace"))
				assert.same({
					'<!--new comment-->',
					'<plainTag',
					'/>',
					'<defaultNamespace',
					'/>',
					'<prefix:namespace',
					'/>',
				}, fragment:write(nil, {
					[DEFAULT_NS_KEY] = "http://ns",
					["prefix"] = "http://pref",
				}))
			end)

		end)

	end)

end)
