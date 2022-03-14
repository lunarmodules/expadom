describe("CDATASection:", function()

	local CDATASection = require "expadom.CDATASection"



	describe("properties:", function()

		it("reports proper nodeName", function()
			local cd = CDATASection { data = "hello world" }
			assert.equal("#cdata-section", cd.nodeName)
		end)


		it("reports proper nodeValue", function()
			local cd = CDATASection { data = "hello world" }
			assert.equal("hello world", cd.nodeValue)
		end)

	end)



	describe("methods:", function()

		local c
		before_each(function()
			c = CDATASection { data = "anything" }
		end)



		describe("write()", function()

			it("exports data and returns buffer", function()
				assert.same({ "<![CDATA[anything]]>" }, c:write({}))
			end)

		end)

	end)

end)
