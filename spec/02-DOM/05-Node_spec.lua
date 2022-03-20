describe("Node", function()

	local TYPES = require("expadom.constants").NODE_TYPES
	local ERRORS = require("expadom.constants").ERRORS

	local Class = require "expadom.class"
	local DOM = require("expadom.DOMImplementation")()
	local Node = require "expadom.Node"
	local Element = require "expadom.Element"
	local Attribute = require "expadom.Attr"
	local NodeList = require "expadom.NodeList"



	describe("initialization", function()

		it("requires a nodeType", function()
			assert.has.error(function()
				Node { nodeType = nil }
			end, "Cannot initialize Node, no nodeType set")
		end)


		it("doesn't allow a parentNode for nodes not supporting it", function()
			local elem = Element { tagName = "node" }
			assert(Class.is_instance_of(Element, elem))

			-- setting parent on element is allowed
			local elem2 = Element {
				tagName = "elem2",
				parentNode = elem,
			}
			assert(Class.is_instance_of(Element, elem2))

			-- setting parent on attribute is not allowed
			assert.has.error(function()
				Node {
					nodeType = TYPES.ATTRIBUTE_NODE,
					parentNode = elem,
				}
			end, "Node type cannot have a parent node")
		end)

	end)



	describe("properties:", function()

		describe("childNodes", function()

			it("is available on all nodeTypes", function()
				-- element has children
				local node = Element { tagName = "node" }
				assert(Class.is_instance_of(NodeList, node.childNodes))

				-- comment has no children
				local node = Element { tagName = "node" }
				assert(Class.is_instance_of(NodeList, node.childNodes))
			end)

		end)



		describe("firstChild", function()

			it("returns the first child node", function()
				local node = Element { tagName = "node" }
				local list = node.childNodes
				local child1 = Element { tagName = "child1" }
				local child2 = Element { tagName = "child2" }
				table.insert(list, child1)
				table.insert(list, child2)

				assert.equal(child1, node.firstChild)
			end)


			it("doesn't fail on nodes without children", function()
				local node = Element { tagName = "node" }
				assert.equal(nil, node.firstChild)
			end)


			it("doesn't fail on nodes not supporting children", function()
				local node = Node { nodeType = TYPES.COMMENT_NODE }
				assert.equal(nil, node.firstChild)
			end)

		end)



		describe("lastChild", function()

			it("returns the last child node", function()
				local node = Element { tagName = "node" }
				local list = node.childNodes
				local child1 = Element { tagName = "child1" }
				local child2 = Element { tagName = "child2" }
				table.insert(list, child1)
				table.insert(list, child2)

				assert.equal(child2, node.lastChild)
			end)


			it("doesn't fail on nodes without children", function()
				local node = Element { tagName = "node" }
				assert.equal(nil, node.lastChild)
			end)


			it("doesn't fail on nodes not supporting children", function()
				local node = Node { nodeType = TYPES.COMMENT_NODE }
				assert.equal(nil, node.lastChild)
			end)

		end)



		describe("nextSibling", function()

			it("returns the proper node", function()
				local node = Element { tagName = "node" }
				local list = node.childNodes
				local child1 = Element {
					tagName = "child1",
					parentNode = node,
				}
				local child2 = Element {
					tagName = "child2",
					parentNode = node,
				}
				local child3 = Element {
					tagName = "child3",
					parentNode = node,
				}
				table.insert(list, child1)
				table.insert(list, child2)
				table.insert(list, child3)

				assert.equal(child2, child1.nextSibling)
				assert.equal(child3, child2.nextSibling)
				assert.equal(nil, child3.nextSibling)
			end)

		end)



		describe("ownerDocument", function()

			local node, child1, child2
			before_each(function()
				node = Node { nodeType = TYPES.DOCUMENT_NODE }
				child1 = Element {
					tagName = "child1",
					parentNode = node,
				}
				node.childNodes[1] = child1
				child2 = Element {
					tagName = "child2",
					parentNode = child1,
				}
				child1.childNodes[1] = child2
			end)


			it("doesn't fail if not set", function()
				node.__prop_values.nodeType = TYPES.ELEMENT_NODE
				assert.equal(nil, child2.ownerDocument)
			end)


			it("looks up document in tree", function()
				assert.equal(node, child2.ownerDocument)
			end)


			it("is lazily set", function()
				assert.equal(nil, child2.__prop_values.ownerDocument)
				assert.equal(node, child2.ownerDocument)
				assert.equal(node, child2.__prop_values.ownerDocument)
			end)

		end)



		describe("previousSibling", function()

			it("returns the proper node", function()
				local node = Element { tagName = "node" }
				local list = node.childNodes
				local child1 = Element {
					tagName = "child1",
					parentNode = node,
				}
				local child2 = Element {
					tagName = "child2",
					parentNode = node,
				}
				local child3 = Element {
					tagName = "child3",
					parentNode = node,
				}
				table.insert(list, child1)
				table.insert(list, child2)
				table.insert(list, child3)

				assert.equal(nil, child1.previousSibling)
				assert.equal(child1, child2.previousSibling)
				assert.equal(child2, child3.previousSibling)
			end)

		end)

	end)



	describe("methods:", function()

		describe("insertChildAtIndex()", function()

			-- this is not a DOM method perse, but underlying to (most) of
			-- the DOM child manipulation methods in this implementation

			it("fails with different ownerDocument", function()
				local node1 = Element { tagName = "node1", ownerDocument = {} }
				local node2 = Element { tagName = "node2" }
				assert.same({
					nil, ERRORS.WRONG_DOCUMENT_ERR
				}, {
					node1:insertChildAtIndex(node2)
				})
			end)


			it("fails if child is an ancestor", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element { tagName = "node2", ownerDocument = node1 }
				local node3 = Element { tagName = "node3", ownerDocument = node1 }
				assert(node1:insertChildAtIndex(node2))
				assert(node2:insertChildAtIndex(node3))
				assert.same({
					nil, ERRORS.HIERARCHY_REQUEST_ERR
				}, {
					node3:insertChildAtIndex(node2)
				})
			end)


			it("fails with unsupported child types (single node)", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Node { nodeType = TYPES.TEXT_NODE }
				assert.same({
					nil, ERRORS.HIERARCHY_REQUEST_ERR
				}, {
					node1:insertChildAtIndex(node2)
				})
			end)


			it("fails with unsupported child types (fragment node)", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local frag = Node { nodeType = TYPES.DOCUMENT_FRAGMENT_NODE }
				local node2 = Node { nodeType = TYPES.TEXT_NODE }
				assert(frag:insertChildAtIndex(node2))
				assert.same({
					nil, ERRORS.HIERARCHY_REQUEST_ERR
				}, {
					node1:insertChildAtIndex(frag)
				})
			end)


			it("updates old parentNode accordingly and sets new parent", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:insertChildAtIndex(node2))
				assert(node1:insertChildAtIndex(node3)) -- as sibling

				-- validate cross references
				assert.equal(node1, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(1))
				assert.equal(node3, node1.childNodes:item(2))

				assert(node2:insertChildAtIndex(node3)) -- sibling -> child

				-- validate cross references
				assert.equal(node1, node2.parentNode)
				assert.equal(node2, node3.parentNode)
				assert.equal(1, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(1))
				assert.equal(1, node2.childNodes.length)
				assert.equal(node3, node2.childNodes:item(1))
			end)

		end)



		describe("appendChild()", function()

			it("adds child nodes", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				assert(node1:appendChild(node3))

				-- validate cross references
				assert.equal(node1, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(1))
				assert.equal(node3, node1.childNodes:item(2))

				-- append again, moves to the end
				assert(node1:appendChild(node2))

				-- validate cross references
				assert.equal(node1, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(2))
				assert.equal(node3, node1.childNodes:item(1))
			end)

		end)



		describe("cloneNode()", function()

			pending("implement", function()
				--test
			end)

		end)



		describe("hasAttributes()", function()

			it("returns false if the attributes NamedNodeMap is empty", function()
				local node1 = Element { tagName = "hello" }
				assert.is.False(node1:hasAttributes())
			end)


			it("returns true if there are attributes", function()
				local node1 = Element { tagName = "hello" }
				local attr1 = Attribute {
					name = "myattrib",
				}
				node1.attributes:setNamedItem(attr1)
				assert.is.True(node1:hasAttributes())
			end)


			it("returns false if the Node type is not an element", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				assert.is.False(node1:hasAttributes())
			end)

		end)



		describe("hasChildNodes()", function()

			it("returns true if there are childNodes", function()
				local node1 = Element { tagName = "tag" }
				assert.is.False(node1:hasChildNodes())
			end)


			it("returns false if the childNodes NodeList is empty", function()
				local node1 = Element { tagName = "tag" }
				local node2 = Element { tagName = "tag" }
				node1:appendChild(node2)
				assert.is.True(node1:hasChildNodes())
			end)


			it("returns false if the Node type doesn't support children", function()
				local node1 = Node { nodeType = TYPES.TEXT_NODE }
				assert.is.False(node1:hasChildNodes())
			end)

		end)



		describe("insertBefore()", function()

			it("appends if refChild is not given", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				assert(node1:insertBefore(node3))

				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(1))
				assert.equal(node3, node1.childNodes:item(2))
			end)


			it("inserts at proper position", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				assert(node1:insertBefore(node3, node2))

				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(2))
				assert.equal(node3, node1.childNodes:item(1))
			end)


			it("returns error if refChild is not found", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				--assert(node1:appendChild(node2))
				assert.same({
					nil, ERRORS.NOT_FOUND_ERR
				}, {
					node1:insertBefore(node3, node2)
				})
			end)

		end)



		describe("isSupported()", function()

			pending("implement", function()
				--test
			end)

		end)



		describe("normalize()", function()

			it("combines adjacent text-nodes (full tree)", function()
				local doc = DOM:createDocument("http://ns", "root")
				local elem = doc.documentElement
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode("hello"))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(" world"))
				elem:appendChild(doc:createTextNode(""))
				local sub = elem:appendChild(doc:createElement("sub"))
				sub:appendChild(doc:createTextNode("hello"))
				sub:appendChild(doc:createTextNode(" world"))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode("bye"))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(" world"))
				elem:appendChild(doc:createTextNode(""))
				elem:normalize()

				local t1 = elem.firstChild
				assert.equal("hello world", t1.data)

				local n1 = elem.childNodes:item(2)
				assert.equal(sub, n1)
				assert.equal("hello world", sub.firstChild.data)

				local t2 = elem.lastChild
				assert.equal("bye world", t2.data)

				assert.equal(3, elem.childNodes.length)
			end)

			it("removes empty text-nodes", function()
				local doc = DOM:createDocument("http://ns", "root")
				local elem = doc.documentElement
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(""))
				local sub = elem:appendChild(doc:createElement("sub"))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(""))
				elem:appendChild(doc:createTextNode(""))
				elem:normalize()

				local n1 = elem.firstChild
				assert.equal(sub, n1)

				assert.equal(1, elem.childNodes.length)
			end)


			it("normalizes (nested) attributes", function()
				local doc = DOM:createDocument("http://ns", "root")
				local elem = doc.documentElement
				local sub = elem:appendChild(doc:createElement("sub"))
				sub:setAttribute("name", "")
				local attr = sub:getAttributeNode("name")
				attr:appendChild(doc:createTextNode(""))
				attr:appendChild(doc:createTextNode("hello"))
				attr:appendChild(doc:createTextNode(" world"))

				elem:normalize()
				assert.equal("hello world", attr.firstChild.data)
				assert.equal(1, attr.childNodes.length)
			end)

		end)



		describe("removeChild()", function()

			it("removes the child node", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				assert(node1:appendChild(node3))

				-- validate cross references
				assert.equal(node1, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(2, node1.childNodes.length)
				assert.equal(node2, node1.childNodes:item(1))
				assert.equal(node3, node1.childNodes:item(2))

				-- append again, moves to the end
				assert.equal(node2, node1:removeChild(node2))

				-- validate cross references
				assert.equal(nil, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(1, node1.childNodes.length)
				assert.equal(node3, node1.childNodes:item(1))
			end)


			it("returns an error if the child node isn't found", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				--assert(node1:appendChild(node3))
				assert.same({
					nil, ERRORS.NOT_FOUND_ERR
				}, {
					node1:removeChild(node3)
				})
			end)

		end)



		describe("replaceChild()", function()

			it("replaces a child node", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				local node3 = Element {
					tagName = "node3",
					ownerDocument = node1
				}
				assert(node1:appendChild(node2))
				assert(node1:replaceChild(node3, node2))

				-- validate cross references
				assert.equal(nil, node2.parentNode)
				assert.equal(node1, node3.parentNode)
				assert.equal(1, node1.childNodes.length)
				assert.equal(node3, node1.childNodes:item(1))
			end)


			it("returns an error if the child node isn't found", function()
				local node1 = Node { nodeType = TYPES.DOCUMENT_NODE }
				local node2 = Element {
					tagName = "node2",
					ownerDocument = node1
				}
				assert.same({
					nil, ERRORS.NOT_FOUND_ERR
				}, {
					node1:removeChild(node2)
				})
			end)

		end)

	end)

end)
