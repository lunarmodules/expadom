describe("DocumentType:", function()

	-- So far most of the tests are with the
	-- DOMImplementation.createDocumentType() method

	local DOM
	before_each(function()
		DOM = require("expadom.DOMImplementation")()
	end)



	describe("methods:", function()

		describe("write()", function()

			it("public external subset", function()
				local doctype = assert(DOM:createDocumentType("prefix:name", "pubid", "sysid"))

				assert.equal([[<!DOCTYPE prefix:name PUBLIC "pubid" "sysid">]], table.concat(doctype:write {}))
			end)


			it("public external subset, with internal subset", function()
				local doctype = assert(DOM:createDocumentType("prefix:name", "pubid", "sysid"))
				doctype.__prop_values.internalSubset = "internal subset goes here"

				assert.equal([[<!DOCTYPE prefix:name PUBLIC "pubid" "sysid" [internal subset goes here]>]], table.concat(doctype:write {}))
			end)


			it("private external subset", function()
				local doctype = assert(DOM:createDocumentType("prefix:name", nil, "sysid"))

				assert.equal([[<!DOCTYPE prefix:name SYSTEM "sysid">]], table.concat(doctype:write {}))
			end)


			it("private external subset, with internal subset", function()
				local doctype = assert(DOM:createDocumentType("prefix:name", nil, "sysid"))
				doctype.__prop_values.internalSubset = "internal subset goes here"

				assert.equal([[<!DOCTYPE prefix:name SYSTEM "sysid" [internal subset goes here]>]], table.concat(doctype:write {}))
			end)

			it("internal subset only", function()
				local doctype = assert(DOM:createDocumentType("prefix:name"))
				doctype.__prop_values.internalSubset = "internal subset goes here"

				assert.equal([[<!DOCTYPE prefix:name [internal subset goes here]>]], table.concat(doctype:write {}))
			end)

		end)

	end)

end)
