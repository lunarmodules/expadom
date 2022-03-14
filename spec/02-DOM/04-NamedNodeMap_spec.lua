describe("NamedNodeMap", function()


	local Class = require "expadom.class"
	local ERRORS = require("expadom.constants").ERRORS
	local NamedNodeMap

	before_each(function()
		NamedNodeMap = require "expadom.NamedNodeMap"
	end)



	describe("Initialization", function()

		it("creates a NamedNodeMap instance", function()
			local map = NamedNodeMap { parentNode = {} }
			assert(Class.is_instance_of(NamedNodeMap, map))
		end)

	end)



	describe("properties:", function()

		describe("length", function()

			it("returns the list size", function()
				local map = NamedNodeMap { parentNode = {} }
				assert.equal(0, map.length)
				map:setNamedItem({ nodeName = "item1"})
				assert.equal(1, map.length)
				map:setNamedItem({ nodeName = "item2"})
				assert.equal(2, map.length)
			end)

		end)


	end)



	describe("methods:", function()

		describe("getNamedItem()", function()

			it("returns the items by name", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = { nodeName = "item1"}
				map:setNamedItem(item1)
				assert.equal(item1, map:getNamedItem("item1"))
			end)


			it("return nil on non-existing names", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = { nodeName = "item1"}
				map:setNamedItem(item1)
				assert.equal(nil, map:getNamedItem("item999"))
			end)

		end)



		describe("getNamedItemNS()", function()

			it("returns the items by name and NS", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = {
					localName = "item1",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item1)
				assert.equal(item1, map:getNamedItemNS("http://namespace", "item1"))
			end)


			it("return nil on non-existing name and NS", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = {
					localName = "item1",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item1)
				assert.equal(nil, map:getNamedItem("http://nameuniverse", "item999"))
			end)

		end)



		describe("item()", function()

			it("returns the items 1-indexed", function()
				local map = NamedNodeMap { parentNode = {} }
				map:setNamedItem({ nodeName = "item1"})
				map:setNamedItem({ nodeName = "item2"})
				assert.equal("item1", map:item(1).nodeName)
				assert.equal("item2", map:item(2).nodeName)
			end)


			it("return nil on non-existing indexes", function()
				local map = NamedNodeMap { parentNode = {} }
				assert.equal(nil, map:item(-1))
				assert.equal(nil, map:item(0))
				assert.equal(nil, map:item(1))
			end)

		end)



		describe("removeNamedItem()", function()

			it("returns the item removed", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = { nodeName = "item1" }
				map:setNamedItem(item1)
				assert.equal(item1, map:removeNamedItem("item1"))
			end)


			it("return error on non-existing names", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = { nodeName = "item1"}
				map:setNamedItem(item1)
				assert.same(
					{ nil, ERRORS.NOT_FOUND_ERR },
					{ map:removeNamedItem("item999") }
				)
			end)


			it("keeps index contiguous", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = { nodeName = "item1" }
				map:setNamedItem(item1)
				local item2 = { nodeName = "item2" }
				map:setNamedItem(item2)
				local item3 = { nodeName = "item3" }
				map:setNamedItem(item3)
				assert.equal(item2, map:removeNamedItem("item2"))

				assert.equal("item1", map:item(1).nodeName)
				assert.equal("item3", map:item(2).nodeName)
				assert.equal(nil, map:item(3))
			end)

		end)



		describe("removeNamedItemNS()", function()

			it("returns the item removed", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = {
					localName = "item1",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item1)
				assert.equal(item1, map:removeNamedItemNS("http://namespace", "item1"))
			end)


			it("return error on non-existing name and NS", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = {
					localName = "item1",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item1)
				assert.same(
					{ nil, ERRORS.NOT_FOUND_ERR },
					{ map:removeNamedItem("http://nameuniverse", "item999") }
				)
			end)


			it("keeps index contiguous", function()
				local map = NamedNodeMap { parentNode = {} }
				local item1 = {
					localName = "item1",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item1)
				local item2 = {
					localName = "item2",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item2)
				local item3 = {
					localName = "item3",
					namespaceURI = "http://namespace",
				}
				map:setNamedItemNS(item3)
				assert.equal(item2, map:removeNamedItemNS("http://namespace", "item2"))

				assert.equal("item1", map:item(1).localName)
				assert.equal("item3", map:item(2).localName)
				assert.equal(nil, map:item(3))
			end)

		end)

    end)

end)
