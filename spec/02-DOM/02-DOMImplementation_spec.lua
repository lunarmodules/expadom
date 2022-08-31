describe("DOMImplementation:", function()

	local Class, DOM, DocumentType, Document
	before_each(function()
		Class = require "expadom.class"
		DOM = require("expadom.DOMImplementation")()
		DocumentType = require "expadom.DocumentType"
		Document = require "expadom.Document"
	end)



	describe("hasFeature()", function()

		pending("to be implemented", function()
			-- TODO: implement
		end)

	end)



	describe("createDocumentType()", function()

		it("creates a new instance", function()
			local doctype, err = DOM:createDocumentType("prefix:name", "pubid", "sysid")
			assert.is_nil(err)
			assert(Class.is_instance_of(DocumentType, doctype))
			assert.equal("prefix:name", doctype.name)
			assert.equal("prefix", doctype.prefix)
			assert.equal("name", doctype.localName)
			assert.equal("pubid", doctype.publicId)
			assert.equal("sysid", doctype.systemId)
		end)


		it("publicId and systemId are optional", function()
			local doctype, err = DOM:createDocumentType("prefix:name")
			assert.is_nil(err)
			assert(Class.is_instance_of(DocumentType, doctype))
			assert.equal("prefix:name", doctype.name)
			assert.equal("prefix", doctype.prefix)
			assert.equal("name", doctype.localName)
			assert.equal(nil, doctype.publicId)
			assert.equal(nil, doctype.systemId)
		end)

	end)



	describe("createDocument()", function()

		it("creates a new instance", function()
			local doctype = assert(DOM:createDocumentType("prefix:name", "pubid", "sysid"))
			local doc, root = assert(DOM:createDocument("http://example.dev/some/path", "ns:root", doctype))

			assert(Class.is_instance_of(Document, doc))

			assert.equal(DOM, doc.implementation)
			assert.equal(doctype, doc.doctype)
			assert.equal(root, doc.documentElement)
			assert.equal("ns", doc.documentElement.prefix)
			assert.equal("root", doc.documentElement.localName)
			assert.equal("ns:root", doc.documentElement.tagName)
			assert.equal("http://example.dev/some/path", doc.documentElement.namespaceURI)

			assert.equal(doc.doctype, doc.childNodes:item(1))
			assert.equal(doc.documentElement, doc.childNodes:item(2))
			assert.equal(2, doc.childNodes.length)
		end)


		it("creates a new instance without DocumentType", function()
			local doc = assert(DOM:createDocument("http://example.dev/some/path", "ns:root"))

			assert(Class.is_instance_of(Document, doc))

			assert.equal(DOM, doc.implementation)
			assert.equal(nil, doc.doctype)
			assert.equal("ns:root", doc.documentElement.tagName)
			assert.equal("http://example.dev/some/path", doc.documentElement.namespaceURI)

			assert.equal(doc.documentElement, doc.childNodes:item(1))
			assert.equal(1, doc.childNodes.length)
		end)


		it("creates a new instance without DocumentType and NS", function()
			local doc = assert(DOM:createDocument(nil, "root"))

			assert(Class.is_instance_of(Document, doc))

			assert.equal(DOM, doc.implementation)
			assert.equal("root", doc.documentElement.tagName)
			assert.equal(nil, doc.documentElement.namespaceURI)

			assert.equal(doc.documentElement, doc.childNodes:item(1))
			assert.equal(1, doc.childNodes.length)
		end)

	end)

end)
