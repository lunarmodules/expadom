describe("Document:", function()

	local TYPES = require("expadom.constants").NODE_TYPES
	local ERRORS = require("expadom.constants").ERRORS

	local DOM = require("expadom.DOMImplementation")()
	local Document = require "expadom.Document"

	local utf8 = require("expadom.xmlutils").utf8
	local valid_utf8_char = string.char(tonumber("CF",16))..string.char(tonumber("8C",16)) -- "\xCF\x8C", either byte alone is invalid.
	-- Repeating it 10 times, so 10 utf8-characters, and 20 bytes.
	local valid_utf8 = valid_utf8_char:rep(10)
	assert(10 == utf8.len(valid_utf8), "expected data to be valid")
	-- Any even number of bytes from the start is VALID.
	-- Any uneven number of bytes from the start is INVALID both for
	-- the first part as well as for the remainder sequence.
	assert(nil == utf8.len(valid_utf8:sub(1,5)), "expected data to be invalid")
	assert(nil == utf8.len(valid_utf8:sub(6,-1)), "expected data to be invalid")
	--local invalid_utf8 = valid_utf8:sub(1,5)



	-- describe("initialization", function()

	-- end)



	describe("properties:", function()

		it("reports proper nodeName", function()
			local doc = Document {}
			assert.equal("#document", doc.nodeName)
		end)


		it("reports proper nodeValue", function()
			local doc = Document {}
			assert.equal(nil, doc.nodeValue)
		end)


		it("reports proper inputEncoding", function()
			local doc = Document {
				inputEncoding = "anything",
			}
			assert.equal("anything", doc.inputEncoding)
		end)


		describe("xmlEncoding", function()

			it("defaults to 'UTF-8'", function()
				local doc = Document {}
				assert.equal("UTF-8", doc.xmlEncoding)
			end)

			it("requires 'UTF-8'", function()
				assert.has.error(function()
					Document { xmlEncoding = "UTF-16" }
				end, "only UTF-8 is supported as xmlEncoding, got: UTF-16")
			end)

		end)



		describe("xmlStandalone", function()

			it("properly reports value", function()
				local doc = Document { xmlStandalone = false }
				assert.equal(false, doc.xmlStandalone)
			end)

			it("accepts boolean and nil when set", function()
				local doc = Document {}
				doc.xmlStandalone = true
				assert.equal(true, doc.xmlStandalone)
				doc.xmlStandalone = false
				assert.equal(false, doc.xmlStandalone)
				doc.xmlStandalone = nil
				assert.equal(nil, doc.xmlStandalone)
			end)

			it("requires boolean or nil as value", function()
				assert.has.error(function()
					Document { xmlStandalone = 123 }
				end, "xmlStandalone must be a boolean or nil")
			end)

		end)



		describe("xmlVersion", function()

			it("defaults to '1.0'", function()
				local doc = Document {}
				assert.equal("1.0", doc.xmlVersion)
			end)


			it("accepts '1.0'", function()
				assert.has.no.error(function()
					Document { xmlVersion = "1.0" }
				end)
			end)


			it("only accepts '1.0' when set", function()
				assert.has.error(function()
					Document { xmlVersion = "123" }
				end, "xmlVersion must be '1.0'")
			end)

		end)



		describe("documentElement", function()

			it("returns the single Element node", function()
				local doc = Document {}
				assert(doc:appendChild(doc:createComment("hello")))
				local elem = doc:createElement("mytag")
				assert(doc:appendChild(elem))
				assert(doc:appendChild(doc:createComment("world")))

				assert.equal(elem, doc.documentElement)
			end)


			it("returns nil if there is none", function()
				local doc = Document {}
				assert(doc:appendChild(doc:createComment("hello")))
				assert(doc:appendChild(doc:createComment("world")))

				assert.equal(nil, doc.documentElement)
			end)

		end)

	end)



	describe("methods:", function()

		describe("appendChild()", function()

			describe("adds children as", function()

				it("single element", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("hello")))
					assert(doc:appendChild(doc:createComment("world")))
					assert.equal("hello", doc.childNodes:item(1).data)
					assert.equal("world", doc.childNodes:item(2).data)
				end)


				it("part of fragemnt", function()
					local doc = Document {}
					local frag = doc:createDocumentFragment()
					assert(frag:appendChild(doc:createComment("hello")))
					assert(frag:appendChild(doc:createComment("world")))
					assert(doc:appendChild(frag))
					assert.equal("hello", doc.childNodes:item(1).data)
					assert.equal("world", doc.childNodes:item(2).data)
				end)

			end)



			describe("allows only 1 element", function()

				it("single element", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createElement("hello")))
					local elem = assert(doc:createElement("world"))
					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:appendChild(elem)
					})
				end)


				it("part of fragemnt", function()
					local doc = Document {}
					local frag = doc:createDocumentFragment()
					assert(frag:appendChild(doc:createElement("hello")))
					assert(frag:appendChild(doc:createElement("world")))
					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:appendChild(frag)
					})
				end)

			end)



			describe("doesn't allow docType", function()

				it("single element", function()
					local doc = Document {}
					local dt = assert(DOM:createDocumentType("ns:name"))
					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:appendChild(dt)
					})
				end)


				-- it("part of fragemnt", function()
				--   -- cannot add a DocumentType to a Fragment, so is ok
				-- end)

			end)

		end)



		describe("insertBefore()", function()

			describe("inserts children as", function()

				it("single element", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("hello")))
					assert(doc:insertBefore(doc:createComment("world"), doc.childNodes:item(1)))
					assert.equal("hello", doc.childNodes:item(2).data)
					assert.equal("world", doc.childNodes:item(1).data)
				end)


				it("part of fragemnt", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("abc")))
					assert(doc:appendChild(doc:createComment("xyz")))
					local frag = doc:createDocumentFragment()
					assert(frag:appendChild(doc:createComment("hello")))
					assert(frag:appendChild(doc:createComment("world")))
					assert(doc:insertBefore(frag, doc.childNodes:item(2)))
					assert.equal("abc", doc.childNodes:item(1).data)
					assert.equal("hello", doc.childNodes:item(2).data)
					assert.equal("world", doc.childNodes:item(3).data)
					assert.equal("xyz", doc.childNodes:item(4).data)
				end)

			end)



			describe("allows only 1 element", function()

				it("single element", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("hello")))
					assert(doc:appendChild(doc:createElement("hello")))
					local elem = assert(doc:createElement("world"))

					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:insertBefore(elem, doc.childNodes:item(1))
					})
				end)


				it("part of fragemnt", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("hello")))
					assert(doc:appendChild(doc:createElement("hello")))
					local frag = doc:createDocumentFragment()
					assert(frag:appendChild(doc:createElement("bye")))

					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:insertBefore(frag, doc.childNodes:item(1))
					})
				end)

			end)



			describe("doesn't allow docType", function()

				it("single element", function()
					local doc = Document {}
					assert(doc:appendChild(doc:createComment("hello")))
					assert(doc:appendChild(doc:createComment("world")))
					local dt = assert(DOM:createDocumentType("ns:name"))
					assert.same({
						nil, ERRORS.INVALID_MODIFICATION_ERR
					}, {
						doc:insertBefore(dt, doc.childNodes:item(1))
					})
				end)


				-- it("part of fragemnt", function()
				--   -- cannot add a DocumentType to a Fragment, so is ok
				-- end)

			end)

		end)



		describe("removeChild()", function()

			it("removes child", function()
				local doc = Document {}
				assert(doc:appendChild(doc:createComment("hello")))
				assert(doc:appendChild(doc:createComment("world")))
				local c1 = doc.childNodes:item(1)
				local c2 = doc.childNodes:item(2)
				assert.equal(c1, doc:removeChild(c1))
				assert.equal(c2, doc:removeChild(c2))
				assert.equal(0, doc.childNodes.length)
			end)


			it("doesn't allow docType removal", function()
				local dt = assert(DOM:createDocumentType("ns:name"))
				local doc = DOM:createDocument("http://ns", "ns:root", dt)
				assert.same({
					nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
				}, {
					doc:removeChild(dt)
				})
			end)

		end)



		describe("replaceChild()", function()

			it("replaces child", function()
				local doc = Document {}
				assert(doc:appendChild(doc:createComment("hello")))
				assert(doc:appendChild(doc:createComment("world")))
				local c1 = doc.childNodes:item(1)
				local c2 = doc.childNodes:item(2)
				assert.equal(c1, doc:replaceChild(c2, c1))
				assert.equal(c2, doc.childNodes:item(1))
				assert.equal(1, doc.childNodes.length)
			end)



			it("can replace documentElement", function()
				local doc = DOM:createDocument("http://ns", "root")
				local elem1 = doc.documentElement
				local elem2 = assert(doc:createElement("hello"))

				assert.equal(elem1, assert(doc:replaceChild(elem2, elem1)))
				assert.equal(elem2, doc.childNodes:item(1))
				assert.equal(elem2, doc.documentElement)
				assert.equal(1, doc.childNodes.length)
			end)



			it("allows only 1 element", function()
				local doc = Document {}
				local com1 = assert(doc:createComment("hello"))
				assert(doc:appendChild(com1))
				local elem1 = assert(doc:createElement("hello"))
				assert(doc:appendChild(elem1))

				local elem2 = assert(doc:createElement("world"))
				assert.same({
					nil, ERRORS.INVALID_MODIFICATION_ERR
				}, {
					doc:replaceChild(elem2, com1)
				})
			end)



			it("doesn't allow removal of docType", function()
				local dt = assert(DOM:createDocumentType("ns:name"))
				local doc = DOM:createDocument("http://ns", "ns:root", dt)
				local com1 = assert(doc:createComment("hello"))
				assert.same({
					nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
				}, {
					doc:replaceChild(com1, dt)
				})
			end)



			it("doesn't allow change of docType", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local com1 = assert(doc:createComment("hello"))
				doc:appendChild(com1)
				local dt = assert(DOM:createDocumentType("ns:name"))
				assert.same({
					nil, ERRORS.NO_MODIFICATION_ALLOWED_ERR
				}, {
					doc:replaceChild(dt, com1)
				})
			end)

		end)



		describe("createAttribute()", function()

			it("creates an attribute", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local attr = doc:createAttribute("hello")
				assert.equal(TYPES.ATTRIBUTE_NODE, attr.nodeType)
				assert.equal(doc, attr.ownerDocument)
				assert.equal("hello", attr.name)
				assert.equal(nil, attr.prefix)
				assert.equal(nil, attr.localName)
				assert.equal(nil, attr.namespaceURI)
			end)

		end)



		describe("createAttributeNS()", function()

			it("creates an attribute", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local attr = doc:createAttributeNS("http://ns", "ns:hello")
				assert.equal(TYPES.ATTRIBUTE_NODE, attr.nodeType)
				assert.equal(doc, attr.ownerDocument)
				assert.equal("ns:hello", attr.name)
				assert.equal("ns", attr.prefix)
				assert.equal("hello", attr.localName)
				assert.equal("http://ns", attr.namespaceURI)
			end)

		end)


		describe("createCDATASection()", function()

			it("creates a cdata", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local cd = doc:createCDATASection("hello world")
				assert.equal(TYPES.CDATA_SECTION_NODE, cd.nodeType)
				assert.equal(doc, cd.ownerDocument)
				assert.equal("hello world", cd.data)
			end)

		end)



		describe("createComment()", function()

			it("creates a comment", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local comm = doc:createComment("hello world")
				assert.equal(TYPES.COMMENT_NODE, comm.nodeType)
				assert.equal(doc, comm.ownerDocument)
				assert.equal("hello world", comm.data)
			end)

		end)



		describe("createDocumentFragment()", function()

			it("creates a fragment", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local df = doc:createDocumentFragment()
				assert.equal(TYPES.DOCUMENT_FRAGMENT_NODE, df.nodeType)
				assert.equal(doc, df.ownerDocument)
			end)

		end)



		describe("createElement()", function()

			it("creates an element", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local elem = doc:createElement("hello")
				assert.equal(TYPES.ELEMENT_NODE, elem.nodeType)
				assert.equal(doc, elem.ownerDocument)
				assert.equal("hello", elem.tagName)
				assert.equal(nil, elem.prefix)
				assert.equal(nil, elem.localName)
				assert.equal(nil, elem.namespaceURI)
			end)

		end)



		describe("createElementNS()", function()

			it("creates an element", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local elem = doc:createElementNS("http://ns", "ns:hello")
				assert.equal(TYPES.ELEMENT_NODE, elem.nodeType)
				assert.equal(doc, elem.ownerDocument)
				assert.equal("ns:hello", elem.tagName)
				assert.equal("ns", elem.prefix)
				assert.equal("hello", elem.localName)
				assert.equal("http://ns", elem.namespaceURI)
			end)

		end)



		pending("createEntityReference()", function()

			pending("creates a text node", function()
				-- TODO: implement
			end)

		end)



		describe("createProcessingInstruction()", function()

			it("creates a ProcessingInstruction node", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local pi = doc:createProcessingInstruction("target", "data")
				assert.equal(TYPES.PROCESSING_INSTRUCTION_NODE, pi.nodeType)
				assert.equal(doc, pi.ownerDocument)
				assert.equal("target", pi.target)
				assert.equal("data", pi.data)
			end)

		end)



		describe("createTextNode()", function()

			it("creates a text node", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				local txt = doc:createTextNode("hello world")
				assert.equal(TYPES.TEXT_NODE, txt.nodeType)
				assert.equal(doc, txt.ownerDocument)
				assert.equal("hello world", txt.data)
			end)

		end)



		describe("getElementById()", function()

			it("always returns nil", function()
				local doc = DOM:createDocument("http://ns", "ns:root", nil)
				assert.equal(nil, doc:getElementById())
			end)

		end)



		describe("getElementsByTagName()", function()

			it("includes documentElement in search", function()
				local doc = assert(DOM:createDocument("https://ns", "ns:root"))
				local root = assert(doc:createElement("root"))
				assert(doc:replaceChild(root, doc.documentElement))

				assert.equal("root", root.tagName)
				local lst = assert(root:getElementsByTagName("root"))
				assert.equal(0, lst.length) -- element doesn't include itself
				local lst = assert(doc:getElementsByTagName("root"))
				assert.equal(1, lst.length) -- document should include root-node
				assert.equal(root, lst:item(1))
			end)

		end)



		describe("getElementsByTagNameNS()", function()

			it("includes documentElement in search", function()
				local doc = assert(DOM:createDocument("http://ns", "ns:root"))
				local root = doc.documentElement

				assert.equal("ns:root", root.tagName)
				local lst = assert(root:getElementsByTagNameNS("http://ns", "root"))
				assert.equal(0, lst.length) -- element doesn't include itself
				local lst = assert(doc:getElementsByTagNameNS("http://ns", "root"))
				assert.equal(1, lst.length) -- document should include root-node
				assert.equal(root, lst:item(1))
			end)

		end)



		pending("importNode()", function()

		end)



		describe("write()", function()

			it("writes a document", function()
				local doc = assert(DOM:createDocument(nil, "root"))
				local root = doc.documentElement
				doc:insertBefore(doc:createProcessingInstruction("piname", "pi data"), root)
				doc:insertBefore(doc:createComment("comment"), root)
				doc:appendChild(doc:createComment("trailing comment"))

				assert.same({
					'<?xml version="',
					'1.0',
					'" encoding="',
					'UTF-8',
					'" ?>\n',
					'<?piname pi data?>',
					'\n',
					'<!--comment-->',
					'\n',
					'<root',
					'/>',
					'\n',
					'<!--trailing comment-->',
					'\n',
				}, doc:write())
			end)


			it("writes 'standalone' in xml declaration", function()
				local doc = assert(DOM:createDocument(nil, "root"))
				doc.xmlStandalone = true
				assert.same({
					'<?xml version="',
					'1.0',
					'" encoding="',
					'UTF-8',
					'" standalone="',
					'yes',
					'" ?>\n',
					'<root',
					'/>',
					'\n',
				}, doc:write())
			end)

		end)

	end)

end)
