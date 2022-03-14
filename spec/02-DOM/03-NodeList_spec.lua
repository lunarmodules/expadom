describe("Node", function()


	local Class = require "expadom.class"
	local NodeList

	before_each(function()
		NodeList = require "expadom.NodeList"
	end)



	describe("Initialization", function()

		it("creates a NodeList instance", function()
			local lst = NodeList()
			assert(Class.is_instance_of(NodeList, lst))
		end)

	end)



	describe("properties:", function()

		describe("length", function()

			it("returns the list size", function()
				local lst = NodeList()
				assert.equal(0, lst.length)
				table.insert(lst, "a")
				assert.equal(1, lst.length)
				table.insert(lst, "b")
				assert.equal(2, lst.length)
			end)

		end)


	end)



	describe("methods:", function()

		describe("item()", function()

			it("returns the items 1-indexed", function()
				local lst = NodeList()
				table.insert(lst, "a")
				table.insert(lst, "b")
				assert.equal("a", lst:item(1))
				assert.equal("b", lst:item(2))
			end)


			it("return nil on non-existing indexes", function()
				local lst = NodeList()
				assert.equal(nil, lst:item(-1))
				assert.equal(nil, lst:item(0))
				assert.equal(nil, lst:item(1))
			end)

		end)

	end)

end)
