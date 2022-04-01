describe("Element:", function()

	local ERRORS = require("expadom.constants").ERRORS
	local DEFAULT_NAMESPACES = require("expadom.constants").DEFAULT_NAMESPACES
	local DEFAULT_NS_KEY = require("expadom.constants").DEFAULT_NS_KEY
	local Class = require "expadom.class"
	local Element = require "expadom.Element"
	local DOM = require("expadom.DOMImplementation")()
	local NamedNodeMap = require "expadom.NamedNodeMap"

	local doc
	before_each(function()
		doc = assert(DOM:createDocument("http://example.dev/some/path", "docns:root"))
	end)



	describe("initialization", function()

		local cases = {
			{
				desc = "simple name",
				input = {
					tagName = "abc"
				},
				output = {
					tagName = "abc",
					qualifiedName = "abc",
					namespaceURI = nil,
					prefix = nil,
					localName = nil,
					nodeName = "abc",
				}
			}, {
				desc = "NS name",
				input = {
					localName = "abc",
					prefix = "ns",
					namespaceURI = "http://ns"
				},
				output = {
					tagName = "ns:abc",
					qualifiedName = "ns:abc",
					namespaceURI = "http://ns",
					prefix = "ns",
					localName = "abc",
					nodeName = "ns:abc",
				}
			}, {
				desc = "simple name as qualifiedName",
				input = {
					qualifiedName = "abc"
				},
				output = {
					tagName = "abc",
					qualifiedName = "abc",
					namespaceURI = nil,
					prefix = nil,
					localName = nil,
					nodeName = "abc",
				}
			}, {
				desc = "qualified name as qualifiedName",
				input = {
					qualifiedName = "ns:abc",
					namespaceURI = "http://ns",
				},
				output = {
					tagName = "ns:abc",
					qualifiedName = "ns:abc",
					namespaceURI = "http://ns",
					prefix = "ns",
					localName = "abc",
					nodeName = "ns:abc",
				}
			}, {
				desc = "nothing specified",
				input = {},
				error = "failed to instantiate `Element`, __init failed: at least tagName, localName or qualifiedName must be given",
			}, {
				desc = "qualifiedName and name",
				input = {
					qualifiedName = "abc",
					tagName = "abc"
				},
				error = "failed to instantiate `Element`, __init failed: tagName, localName, and prefix must be nil if qualifiedName is given",
			}, {
				desc = "qualifiedName and localName",
				input = {
					qualifiedName = "ns:abc",
					localName = "abc"
				},
				error = "failed to instantiate `Element`, __init failed: tagName, localName, and prefix must be nil if qualifiedName is given",
			}, {
				desc = "qualifiedName and prefix",
				input = {
					qualifiedName = "ns:abc",
					prefix = "ns"
				},
				error = "failed to instantiate `Element`, __init failed: tagName, localName, and prefix must be nil if qualifiedName is given",
			}, {
				desc = "qualifiedName (without prefix) and namespaceURI result in namespaced",
				input = {
					qualifiedName = "abc",
					namespaceURI = "http://ns",
				},
				output = {
					tagName = "abc",
					qualifiedName = "abc",
					namespaceURI = "http://ns",
					prefix = nil,
					localName = "abc",
					nodeName = "abc"
				}
			}, {
				desc = "qualifiedName (without prefix) and NO namespaceURI result in simple/level 1",
				input = {
					qualifiedName = "abc",
				},
				output = {
					tagName = "abc",
					qualifiedName = "abc",
					namespaceURI = nil,
					prefix = nil,
					localName = nil,
					nodeName = "abc"
				}
			}, {
				desc = "name and localName",
				input = {
					localName = "abc",
					tagName = "abc"
				},
				error = "failed to instantiate `Element`, __init failed: cannot specify both tagName and localName",
			}, {
				desc = "name and prefix",
				input = {
					prefix = "ns",
					tagName = "abc"
				},
				error = "failed to instantiate `Element`, __init failed: cannot specify namespace attributes (prefix or namespaceURI) with simple DOM level 1 name",
			}, {
				desc = "name and namespaceURI",
				input = {
					namespaceURI = "http://ns",
					tagName = "abc"
				},
				error = "failed to instantiate `Element`, __init failed: cannot specify namespace attributes (prefix or namespaceURI) with simple DOM level 1 name",
			}, {
				desc = "localName, prefix without namespaceURI",
				input = {
					localName = "abc",
					prefix = "ns",
				},
				error = "failed to instantiate `Element`, __init failed: namespaceURI is required when specifying a prefix",
			}, {
				desc = "prefix 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'",
				input = {
					qualifiedName = "xml:abc",
					namespaceURI = "http://www.w3.org/XML/1998/namespace",
				},
				output = {
					tagName = "xml:abc",
					qualifiedName = "xml:abc",
					namespaceURI = "http://www.w3.org/XML/1998/namespace",
					prefix = "xml",
					localName = "abc",
					nodeName = "xml:abc"
				}
			}, {
				desc = "prefix 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'",
				input = {
					qualifiedName = "xml:abc",
					namespaceURI = "http://ns",
				},
				error = "failed to instantiate `Element`, __init failed: prefix 'xml' is reserved for namespace 'http://www.w3.org/XML/1998/namespace'"
			}}

			for i, case in ipairs(cases) do
				it((case.error and "fail: " or "success: ")..case.desc, function()
					if case.error then
						assert.has.error(function()
							Element(case.input)
						end, case.error)
					else
						local attr, err
						assert.has.no.error(function()
							attr, err = Element(case.input)
						end)
						assert.equal(nil, err)
						assert.equal(case.output.tagName, attr.tagName)
						assert.equal(case.output.qualifiedName, attr.qualifiedName)
						assert.equal(case.output.namespaceURI, attr.namespaceURI)
						assert.equal(case.output.localName, attr.localName)
						assert.equal(case.output.prefix, attr.prefix)
					end
				end)
			end

	end)



	describe("properties:", function()

		it("reports proper nodeName", function()
			local elem = doc:createElementNS("http://ns", "ns:mytag")
			assert.equal("ns:mytag", elem.nodeName)
		end)


		it("reports proper nodeValue", function()
			local elem = doc:createElementNS("http://ns", "ns:mytag")
			assert.equal(nil, elem.nodeValue)
		end)



		describe("attributes", function()

			it("is only available on an Element node", function()
				local node = doc:createElement("tagname")
				assert(Class.is_instance_of(NamedNodeMap, node.attributes))
			end)

		end)



		describe("prefix:", function()

			it("setting 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'", function()
				local node = doc:createElementNS("http://www.w3.org/XML/1998/namespace","ns:tagname")
				assert.has.no.error(function()
					node.prefix = "xml"
				end)

				local node = doc:createElementNS("http://ns","ns:tagname")
				assert.has.error(function()
					node.prefix = "xml"
				end, ERRORS.NAMESPACE_ERR)
			end)

		end)

	end)



	describe("methods:", function()

		local elem
		before_each(function()
			elem = doc:createElement("root")
		end)


		describe("setAttribute()", function()

			it("creates an attribute", function()
				assert(elem:setAttribute("hello", "world"))
				local attr = assert(elem.attributes:getNamedItem("hello"))
				assert.equal("hello", attr.name)
				assert.equal("world", attr.value)
				assert.equal(nil, attr.localName)
				assert.equal(nil, attr.prefix)
				assert.equal(nil, attr.namespaceURI)
				assert.equal(elem, attr.ownerElement)
			end)


			it("updates an attribute", function()
				assert(elem:setAttribute("hello", "world"))
				local attr1 = assert(elem.attributes:getNamedItem("hello"))
				assert(elem:setAttribute("hello", "universe"))
				local attr2 = assert(elem.attributes:getNamedItem("hello"))
				assert.equal("hello", attr2.name)
				assert.equal("universe", attr2.value)
				assert.equal(nil, attr2.localName)
				assert.equal(nil, attr2.prefix)
				assert.equal(nil, attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(attr1, attr2)
			end)

		end)



		describe("setAttributeNS()", function()

			it("creates an attribute", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				local attr = assert(elem.attributes:getNamedItemNS("http://namespace", "hello"))
				assert.equal("ns:hello", attr.name)
				assert.equal("world", attr.value)
				assert.equal("hello", attr.localName)
				assert.equal("ns", attr.prefix)
				assert.equal("http://namespace", attr.namespaceURI)
				assert.equal(elem, attr.ownerElement)
			end)


			it("updates an attribute", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				local attr1 = assert(elem.attributes:getNamedItemNS("http://namespace", "hello"))
				assert(elem:setAttributeNS("http://namespace", "ns2:hello", "universe"))
				local attr2 = assert(elem.attributes:getNamedItemNS("http://namespace", "hello"))
				assert.equal("ns2:hello", attr2.name)
				assert.equal("universe", attr2.value)
				assert.equal("hello", attr2.localName)
				assert.equal("ns2", attr2.prefix)
				assert.equal("http://namespace", attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(attr1, attr2)
			end)


		end)



		describe("setAttributeNode()", function()

			it("adds an attribute", function()
				local attr1 = assert(doc:createAttribute("hello"))
				attr1.value = "world"
				assert(elem:setAttributeNode(attr1))

				local attr2 = assert(elem.attributes:getNamedItem("hello"))
				assert.equal("hello", attr2.name)
				assert.equal("world", attr2.value)
				assert.equal(nil, attr2.localName)
				assert.equal(nil, attr2.prefix)
				assert.equal(nil, attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(attr1, attr2)
			end)


			it("replaces an attribute", function()
				local attr1 = assert(doc:createAttribute("hello"))
				attr1.value = "world"
				assert(elem:setAttributeNode(attr1))

				local attr2 = assert(doc:createAttribute("hello"))
				attr2.value = "universe"
				local replaced_attr = assert(elem:setAttributeNode(attr2))

				local attr3 = assert(elem.attributes:getNamedItem("hello"))
				assert.equal("hello", attr2.name)
				assert.equal("universe", attr2.value)
				assert.equal(nil, attr2.localName)
				assert.equal(nil, attr2.prefix)
				assert.equal(nil, attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(nil, attr1.ownerElement)
				assert.equal(attr3, attr2)
				assert.not_equal(attr1, attr3)
				assert.equal(attr1, replaced_attr)
			end)

		end)



		describe("setAttributeNodeNS()", function()

			it("adds an attribute", function()
				local attr1 = assert(doc:createAttributeNS("http://namespace", "ns:hello"))
				attr1.value = "world"
				assert(elem:setAttributeNodeNS(attr1))

				local attr2 = assert(elem.attributes:getNamedItemNS("http://namespace", "hello"))
				assert.equal("ns:hello", attr2.name)
				assert.equal("world", attr2.value)
				assert.equal("hello", attr2.localName)
				assert.equal("ns", attr2.prefix)
				assert.equal("http://namespace", attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(attr1, attr2)
			end)


			it("replaces an attribute", function()
				local attr1 = assert(doc:createAttributeNS("http://namespace", "ns:hello"))
				attr1.value = "world"
				assert(elem:setAttributeNodeNS(attr1))

				local attr2 = assert(doc:createAttributeNS("http://namespace", "ns2:hello"))
				attr2.value = "universe"
				local replaced_attr = assert(elem:setAttributeNodeNS(attr2))

				local attr3 = assert(elem.attributes:getNamedItemNS("http://namespace", "hello"))
				assert.equal("ns2:hello", attr2.name)
				assert.equal("universe", attr2.value)
				assert.equal("hello", attr2.localName)
				assert.equal("ns2", attr2.prefix)
				assert.equal("http://namespace", attr2.namespaceURI)
				assert.equal(elem, attr2.ownerElement)
				assert.equal(nil, attr1.ownerElement)
				assert.equal(attr3, attr2)
				assert.not_equal(attr1, attr3)
				assert.equal(attr1, replaced_attr)
			end)

		end)



		describe("getAttribute()", function()

			it("returns the attribute", function()
				assert(elem:setAttribute("hello", "world"))
				assert.equal("world", elem:getAttribute("hello"))
			end)


			it("returns nil if not found", function()
				assert.same({nil}, {elem:getAttribute("hello")})
			end)

		end)



		describe("getAttributeNS()", function()

			it("returns the attribute", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				assert.equal("world", elem:getAttributeNS("http://namespace", "hello"))
			end)


			it("returns nil if not found", function()
				assert.same({nil}, {elem:getAttributeNS("http://namespace", "hello")})
			end)

		end)



		describe("getAttributeNode()", function()

			it("returns the attribute", function()
				assert(elem:setAttribute("hello", "world"))
				assert.equal("world", elem:getAttributeNode("hello").value)
			end)


			it("returns nil if not found", function()
				assert.same({nil}, {elem:getAttributeNode("hello")})
			end)

		end)



		describe("getAttributeNodeNS()", function()

			it("returns the attribute", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				assert.equal("world", elem:getAttributeNodeNS("http://namespace", "hello").value)
			end)


			it("returns nil if not found", function()
				assert.same({nil}, {elem:getAttributeNodeNS("http://namespace", "hello")})
			end)

		end)



		describe("removeAttribute()", function()

			it("removes the attribute", function()
				assert(elem:setAttribute("hello", "world"))
				local attr1 = assert(elem:getAttributeNode("hello"))
				assert.equal(elem, attr1.ownerElement)
				assert(elem:removeAttribute("hello"))
				assert.same({nil}, {elem:getAttribute("hello")})
				assert.equal(nil, attr1.ownerElement)
			end)


			it("doesn't fail if not found", function()
				assert(elem:removeAttribute("hello"))
				assert.same({nil}, {elem:getAttribute("hello")})
			end)


			pending("with default attributes", function()
			end)

		end)



		describe("removeAttributeNS()", function()

			it("removes the attribute", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				local attr1 = assert(elem:getAttributeNodeNS("http://namespace", "hello"))
				assert.equal(elem, attr1.ownerElement)
				assert(elem:removeAttributeNS("http://namespace", "hello"))
				assert.same({nil}, {elem:getAttributeNS("http://namespace", "hello")})
				assert.equal(nil, attr1.ownerElement)
			end)


			it("doesn't fail if not found", function()
				assert(elem:removeAttributeNS("http://namespace", "ns:hello", "world"))
				assert.same({nil}, {elem:getAttributeNodeNS("http://namespace", "hello")})
			end)


			pending("with default attributes", function()
			end)

		end)



		describe("removeAttributeNode()", function()

			it("removes the attribute and returns it", function()
				assert(elem:setAttribute("hello", "world"))
				local attr1 = assert(elem:getAttributeNode("hello"))
				local attr2 = assert(elem:removeAttributeNode(attr1))
				assert.equal(attr1, attr2)
				assert.equal(nil, attr2.ownerElement)
			end)


			it("removes the NSattribute and returns it", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				local attr1 = assert(elem:getAttributeNodeNS("http://namespace", "hello"))
				local attr2 = assert(elem:removeAttributeNode(attr1))
				assert.equal(attr1, attr2)
				assert.equal(nil, attr2.ownerElement)
			end)

			it("returns error if not found", function()
				assert(elem:setAttribute("hello", "world"))
				local attr1 = assert(elem:getAttributeNode("hello"))
				assert(elem:removeAttributeNode(attr1))  -- remove once
				assert.same({nil, ERRORS.NOT_FOUND_ERR }, {elem:removeAttributeNode(attr1)})  -- remove again
			end)


			pending("with default attributes", function()
			end)

		end)



		describe("hasAttribute()", function()

			it("returns a boolean", function()
				assert(elem:setAttribute("hello", "world"))
				assert.is_true(elem:hasAttribute("hello"))
				assert.is_false(elem:hasAttribute("goodbye"))
			end)


			pending("with default attributes", function()
			end)

		end)



		describe("hasAttributeNS()", function()

			it("returns a boolean", function()
				assert(elem:setAttributeNS("http://namespace", "ns:hello", "world"))
				assert.is_true(elem:hasAttributeNS("http://namespace", "hello"))
				assert.is_false(elem:hasAttributeNS("http://namespace", "goodbye"))
			end)


			pending("with default attributes", function()
			end)

		end)



		describe("getElementsByTagName()", function()

			local node1, node2, node1a, node1b, node2a, node2b
			before_each(function()
				assert(elem:appendChild(doc:createComment("a comment")))
				node1 = assert(elem:appendChild(doc:createElement("node")))
				node1a = assert(node1:appendChild(doc:createElement("node-a")))
				node1b = assert(node1:appendChild(doc:createElement("node")))
				assert(elem:appendChild(doc:createComment("a comment")))
				node2 = assert(elem:appendChild(doc:createElement("node")))
				node2a = assert(node2:appendChild(doc:createElement("node")))
				node2b = assert(node2:appendChild(doc:createElement("node-a")))
				assert(elem:appendChild(doc:createComment("a comment")))
			end)

			it("returns empty list if nothing found", function()
				local lst = assert(elem:getElementsByTagName("not-to-be-found"))
				assert.equal(0, lst.length)
			end)


			it("excludes the node called upon", function()
				assert.equal("root", elem.tagName)
				local lst = assert(elem:getElementsByTagName("root"))
				assert.equal(0, lst.length)
			end)


			it("returns all nodes with wildcard '*', proper order", function()
				local lst = assert(elem:getElementsByTagName("*"))
				assert.equal(node1, lst[1])
				assert.equal(node1a, lst[2])
				assert.equal(node1b, lst[3])
				assert.equal(node2, lst[4])
				assert.equal(node2a, lst[5])
				assert.equal(node2b, lst[6])
				assert.equal(6, lst.length)
			end)


			it("returns only nodes matched, proper order", function()
				local lst = assert(elem:getElementsByTagName("node-a"))
				assert.equal(node1a, lst[1])
				assert.equal(node2b, lst[2])
				assert.equal(2, lst.length)
			end)

		end)



		describe("getElementsByTagNameNS()", function()

			local node1, node2, node1b, node2a, node2b
			before_each(function()
				assert(elem:appendChild(doc:createComment("a comment")))
				node1 = assert(elem:appendChild(doc:createElement("node")))
				assert(node1:appendChild(doc:createElement("node-a")))
				node1b = assert(node1:appendChild(doc:createElementNS("http://ns", "ns:node")))
				assert(elem:appendChild(doc:createComment("a comment")))
				node2 = assert(elem:appendChild(doc:createElementNS("http://ns", "ns:node")))
				node2a = assert(node2:appendChild(doc:createElementNS("http://xyz", "ns:node")))
				node2b = assert(node2:appendChild(doc:createElementNS("http://ns", "ns:node-a")))
				assert(elem:appendChild(doc:createComment("a comment")))
			end)

			it("returns empty list if nothing found", function()
				local lst = assert(elem:getElementsByTagNameNS("http://ns", "not-to-be-found"))
				assert.equal(0, lst.length)
			end)


			it("returns all nodes with wildcard '*', proper order", function()
				local lst = assert(elem:getElementsByTagNameNS("*", "*"))
				assert.equal(node1b, lst[1])
				assert.equal(node2, lst[2])
				assert.equal(node2a, lst[3])
				assert.equal(node2b, lst[4])
				assert.equal(4, lst.length)

				local lst = assert(elem:getElementsByTagNameNS("http://ns", "*"))
				assert.equal(node1b, lst[1])
				assert.equal(node2, lst[2])
				assert.equal(node2b, lst[3])
				assert.equal(3, lst.length)

				local lst = assert(elem:getElementsByTagNameNS("*", "node"))
				assert.equal(node1b, lst[1])
				assert.equal(node2, lst[2])
				assert.equal(node2a, lst[3])
				assert.equal(3, lst.length)
			end)


			it("returns only nodes matched, proper order", function()
				local lst = assert(elem:getElementsByTagNameNS("http://ns", "node-a"))
				assert.equal(node2b, lst[1])
				assert.equal(1, lst.length)
			end)

		end)



		describe("defineNamespace", function()

			it("creates a namespace attribute", function()
				local elem = doc:createElement("elem")
				local attr = assert(elem:defineNamespace("http://my_namespace", "prefix"))
				assert.equal(DEFAULT_NAMESPACES.xmlns, attr.namespaceURI)
				assert.equal("xmlns", attr.prefix)
				assert.equal("prefix", attr.localName)
				assert.equal("xmlns:prefix", attr.qualifiedName)
				assert.equal("http://my_namespace", attr.value)
			end)


			it("updates existing namespace attribute", function()
				local elem = doc:createElement("elem")
				local attr = assert(elem:defineNamespace("http://my_namespace", "prefix"))
				local attr2 = assert(elem:defineNamespace("http://my_other_namespace", "prefix"))
				assert.equal(attr, attr2) -- same; existing one updated
				assert.equal(DEFAULT_NAMESPACES.xmlns, attr.namespaceURI)
				assert.equal("xmlns", attr.prefix)
				assert.equal("prefix", attr.localName)
				assert.equal("xmlns:prefix", attr.qualifiedName)
				assert.equal("http://my_other_namespace", attr.value)
			end)


			it("creates a default namespace attribute", function()
				local elem = doc:createElement("elem")
				local attr = assert(elem:defineNamespace("http://my_namespace"))
				assert.equal(DEFAULT_NAMESPACES.xmlns, attr.namespaceURI)
				assert.equal(nil, attr.prefix)
				assert.equal("xmlns", attr.localName)
				assert.equal("xmlns", attr.name)
				assert.equal("xmlns", attr.qualifiedName)
				assert.equal("http://my_namespace", attr.value)
			end)


			it("updates existing default namespace attribute", function()
				local elem = doc:createElement("elem")
				local attr = assert(elem:defineNamespace("http://my_namespace"))
				local attr2 = assert(elem:defineNamespace("http://my_other_namespace"))
				assert.equal(attr, attr2) -- same; existing one updated
				assert.equal(DEFAULT_NAMESPACES.xmlns, attr.namespaceURI)
				assert.equal(nil, attr.prefix)
				assert.equal("xmlns", attr.localName)
				assert.equal("xmlns", attr.name)
				assert.equal("xmlns", attr.qualifiedName)
				assert.equal("http://my_other_namespace", attr.value)
			end)


			it("won't allow setting default xml/xmlns namespaces", function()
				local elem = doc:createElement("elem")
				assert.has.error(function()
					elem:defineNamespace("http://my_namespace", "xmlns")
				end, "prefix 'xmlns' has a default namespaceURI and cannot be set")
				assert.has.error(function()
					elem:defineNamespace("http://my_namespace", "xml")
				end, "prefix 'xml' has a default namespaceURI and cannot be set")
			end)

		end)



		describe("write()", function()

			it("exports escaped data and returns buffer", function()
				local elem = doc:createElement("elem")
				elem:setAttribute("attr1", "a 'value'")
				elem:appendChild(doc:createComment("a comment"))
				elem:appendChild(doc:createElement("child"))
				assert.equal([[<elem attr1="a &apos;value&apos;"><!--a comment--><child/></elem>]],
					table.concat(elem:write({}, {})))
			end)

			it("adds default namespace definition", function()
				local elem = doc:createElementNS("http://ns", "elem")
				assert.equal([[<elem xmlns="http://ns"/>]], table.concat(elem:write({}, {})))
			end)


			it("skips default namespace definition if already defined", function()
				local elem = doc:createElementNS("http://ns", "elem")
				assert.equal([[<elem/>]], table.concat(elem:write({}, {
					[DEFAULT_NS_KEY] = "http://ns"
				})))
			end)


			it("adds namespace definition from element", function()
				local elem = doc:createElementNS("http://ns", "prefix:elem")
				assert.equal([[<prefix:elem xmlns:prefix="http://ns"/>]], table.concat(elem:write({}, {})))
			end)


			it("skips namespace definition from element if already defined", function()
				local elem = doc:createElementNS("http://ns", "prefix:elem")
				assert.equal([[<prefix:elem/>]], table.concat(elem:write({}, {
					prefix = "http://ns"
				})))
			end)


			it("adds namespace definitions from attributes", function()
				local elem = doc:createElementNS("http://ns1", "prefix1:elem")
				elem:setAttributeNS("http://ns1", "prefix1:attr1", "a 'value'")
				elem:setAttributeNS("http://ns2", "prefix2:attr2", "'value' two")
				assert.equal([[<prefix1:elem xmlns:prefix1="http://ns1" prefix1:attr1="a &apos;value&apos;" xmlns:prefix2="http://ns2" prefix2:attr2="&apos;value&apos; two"/>]],
					table.concat(elem:write({}, {})))
			end)


			it("skips namespace definitions from attributes if already defined", function()
				local elem = doc:createElementNS("http://ns1", "prefix1:elem")
				elem:setAttributeNS("http://ns1", "prefix1:attr1", "a 'value'")
				elem:setAttributeNS("http://ns2", "prefix2:attr2", "'value' two")
				assert.equal([[<prefix1:elem prefix1:attr1="a &apos;value&apos;" prefix2:attr2="&apos;value&apos; two"/>]],
					table.concat(elem:write({}, {
						prefix1 = "http://ns1",
						prefix2 = "http://ns2",
					})))
			end)


			it("adds explicit namespaces definitions", function()
				local elem = doc:createElement("elem")
				assert(elem:defineNamespace("http://explct", "explicitOne"))
				assert.equal([[<elem xmlns:explicitOne="http://explct"/>]],
					table.concat(elem:write({}, {})))
			end)


			it("fails if duplicate prefixes are used by element and attribute", function()
				local elem = doc:createElementNS("http://ns1", "prefix:elem")
				assert(elem:setAttributeNS("http://ns2", "prefix:attr", "a 'value'")) -- same prefix, different URI!!
				assert.has.error(function()
					elem:write({}, {})
				end, "prefix 'prefix' has 2 URIs defined on the same element; 'http://ns1' and 'http://ns2'")
			end)


			it("fails if duplicate prefixes are used by element and namespace attribute", function()
				local elem = doc:createElementNS("http://ns1", "prefix:elem")
				assert(elem:defineNamespace("http://ns2", "prefix"))
				assert.has.error(function()
					elem:write({}, {})
				end, "prefix 'prefix' has 2 URIs defined on the same element; 'http://ns2' and 'http://ns1'")
			end)


			it("fails if duplicate prefixes are used by 2 attributes", function()
				local elem = doc:createElement("elem")
				assert(elem:setAttributeNS("http://ns1", "prefix:attr1", "a 'value'"))
				assert(elem:setAttributeNS("http://ns2", "prefix:attr2", "a 'value'")) -- same prefix, different URI!!
				assert.has.error(function()
					elem:write({}, {})
				end, "prefix 'prefix' has 2 URIs defined on the same element; 'http://ns1' and 'http://ns2'")
			end)


			it("fails if duplicate prefixes are used by attribute and namespace attribute", function()
				local elem = doc:createElement("elem")
				assert(elem:setAttributeNS("http://ns1", "prefix:attr1", "a 'value'"))
				assert(elem:defineNamespace("http://ns2", "prefix")) -- same prefix, different URI!!
				assert.has.error(function()
					elem:write({}, {})
				end, "prefix 'prefix' has 2 URIs defined on the same element; 'http://ns2' and 'http://ns1'")
			end)

		end)

	end)

end)
