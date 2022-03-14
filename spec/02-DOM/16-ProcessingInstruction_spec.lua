describe("ProcessingInstruction:", function()

	local ProcessingInstruction = require "expadom.ProcessingInstruction"


	describe("initialization", function()

		it("creates a PI", function()
			local pi = ProcessingInstruction {
				data = "some data",
				target = "some_name",
			}
			assert.equal("some_name", pi.target)
			assert.equal("some data", pi.data)
		end)

	end)



	describe("properties:", function()

		it("reports proper nodeName", function()
			local pi = ProcessingInstruction {
				data = "some data",
				target = "some_name",
			}
			assert.equal("some_name", pi.nodeName)
		end)


		it("reports proper nodeValue", function()
			local pi = ProcessingInstruction {
				data = "some data",
				target = "some_name",
			}
			assert.equal("some data", pi.nodeValue)
		end)

	end)



	describe("methods:", function()

		describe("write()", function()

			it("exports data and returns buffer", function()
				local pi = ProcessingInstruction {
					data = "some data",
					target = "some_name",
				}
				assert.same({ "<?some_name some data?>" }, pi:write({}))
			end)

		end)

	end)

end)
