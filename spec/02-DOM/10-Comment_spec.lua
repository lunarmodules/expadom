describe("Comment:", function()

	local ERRORS = require("expadom.constants").ERRORS
	local Comment = require "expadom.Comment"

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
	local invalid_utf8 = valid_utf8:sub(1,5)

	describe("initialization", function()

		it("requires a data", function()
			assert.has.error(function()
				Comment {}
			end, "expected data to be a string")

			local c = Comment { data = "anything" }
			assert.equal("anything", c.data)
		end)

	end)



	describe("properties:", function()

		local c
		before_each(function()
			c = Comment { data = "anything" }
		end)


		it("reports proper nodeName", function()
			assert.equal("#comment", c.nodeName)
		end)


		it("reports proper nodeValue", function()
			assert.equal("anything", c.nodeValue)
		end)


		describe("data", function()

			it("is settable", function()
				c.data = "hello"
				assert.equal("hello", c.data)
			end)


			it("doesn't accept non-string data", function()
				assert.has.error(function()
					c.data = 123
				end, "expected data to be a string")
			end)


			it("doesn't accept invalid utf8", function()
				assert.has.error(function()
					c.data = invalid_utf8
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)

		end)

		describe("length", function()

			it("gets set to proper utf8 length", function()
				c.data = valid_utf8
				assert.equal(20, #c.data)	-- in bytes
				assert.equal(10, c.length)		-- in characters
				c.data = ""
				assert.equal(0, c.length)		-- in characters
			end)

		end)


	end)



	describe("methods:", function()

		local c
		before_each(function()
			c = Comment { data = "anything" }
		end)



		describe("appendData()", function()

			it("appends valid data", function()
				c.data = valid_utf8
				c:appendData(valid_utf8)
				assert.equal(20 + 20, #c.data)	-- in bytes
				assert.equal(10 + 10, c.length)		-- in characters
			end)


			it("fails on invalid type data", function()
				c.data = valid_utf8
				assert.has.error(function()
					c:appendData(invalid_utf8)
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)


			it("fails on invalid utf8 data", function()
				c.data = valid_utf8
				assert.has.error(function()
					c:appendData(invalid_utf8)
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)

		end)



		describe("deleteData()", function()

			it("deletes data", function()
				-- from start
				c.data = (valid_utf8_char.." "):rep(5)
				c:deleteData(1, 3)
				assert.equal(" "..(valid_utf8_char.." "):rep(3), c.data)

				-- middle
				c.data = (valid_utf8_char.." "):rep(5)
				c:deleteData(3, 5)
				assert.equal(valid_utf8_char.."  "..valid_utf8_char.." ", c.data)

				-- end
				c.data = (valid_utf8_char.." "):rep(5)
				c:deleteData(3, 8)
				assert.equal(valid_utf8_char.." ", c.data)

				-- beyond end
				c.data = (valid_utf8_char.." "):rep(5)
				c:deleteData(3, 999)
				assert.equal(valid_utf8_char.." ", c.data)
			end)


			it("fails on invalid offset", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:deleteData(99, 1)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:deleteData(-99, 1)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:deleteData(0, 1)
				})
			end)


			it("fails on invalid count", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:deleteData(2, -1)
				})
			end)

		end)



		describe("insertData()", function()

			it("inserts data", function()
				-- from start
				c.data = (valid_utf8_char.." "):rep(5)
				c:insertData(1, "abc")
				assert.equal("abc"..(valid_utf8_char.." "):rep(5), c.data)

				-- middle
				c.data = (valid_utf8_char.." "):rep(5)
				c:insertData(6, "abc")
				assert.equal((valid_utf8_char.." "):rep(2) .. valid_utf8_char .. "abc "..(valid_utf8_char.." "):rep(2), c.data)

				-- end
				c.data = (valid_utf8_char.." "):rep(5)
				c:insertData(10, "abc")
				assert.equal((valid_utf8_char.." "):rep(4)..valid_utf8_char.."abc ", c.data)
			end)


			it("fails on invalid offset", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:insertData(99, "abc")
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:insertData(-99, "abc")
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:insertData(0, "abc")
				})
			end)


			it("fails on invalid utf8 data", function()
				assert.has.error(function()
					c:insertData(2, invalid_utf8)
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)

		end)



		describe("replaceData()", function()

			it("replaces data", function()
				-- from start
				c.data = (valid_utf8_char.." "):rep(5)
				c:replaceData(1, 3, "abc")
				assert.equal("abc "..(valid_utf8_char.." "):rep(3), c.data)

				-- middle
				c.data = (valid_utf8_char.." "):rep(5)
				c:replaceData(3, 5, "abc")
				assert.equal(valid_utf8_char.." abc "..valid_utf8_char.." ", c.data)

				-- end
				c.data = (valid_utf8_char.." "):rep(5)
				c:replaceData(3, 8, "abc")
				assert.equal(valid_utf8_char.." abc", c.data)

				-- beyond end
				c.data = (valid_utf8_char.." "):rep(5)
				c:replaceData(3, 999, "abc")
				assert.equal(valid_utf8_char.." abc", c.data)
			end)


			it("fails on invalid offset", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:replaceData(99, 1, "abc")
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:replaceData(-99, 1, "abc")
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:replaceData(0, 1, "abc")
				})
			end)


			it("fails on invalid count", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:replaceData(2, -1, "abc")
				})
			end)


			it("fails on invalid utf8 data", function()
				assert.has.error(function()
					c:replaceData(2, 2, invalid_utf8)
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)

		end)



		describe("substringData()", function()

			it("returns the substring", function()
				-- from start
				c.data = (valid_utf8_char.." "):rep(5)
				assert.equal(valid_utf8_char.." "..valid_utf8_char, c:substringData(1, 3))

				-- middle
				c.data = (valid_utf8_char.." "):rep(5)
				assert.equal(valid_utf8_char.." "..valid_utf8_char.." "..valid_utf8_char, c:substringData(3, 5))

				-- end
				c.data = (valid_utf8_char.." "):rep(5)
				assert.equal(valid_utf8_char.." ", c:substringData(9, 2))

				-- beyond end
				c.data = (valid_utf8_char.." "):rep(5)
				assert.equal(valid_utf8_char.." ", c:substringData(9, 999))
			end)


			it("fails on invalid offset", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:substringData(99, 1)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:substringData(-99, 1)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:substringData(0, 1)
				})
			end)


			it("fails on invalid count", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					c:substringData(2, -1)
				})
			end)

		end)



		describe("write()", function()

			it("exports data and returns buffer", function()
				assert.same({ "<!--anything-->" }, c:write({}))
			end)

		end)

	end)

end)
