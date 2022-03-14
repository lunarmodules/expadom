describe("Text:", function()

	local TYPES = require("expadom.constants").NODE_TYPES
	local ERRORS = require("expadom.constants").ERRORS

	local DOM = require("expadom.DOMImplementation")()
	local Text = require "expadom.Text"

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

	describe("initialization", function()

		it("requires a data", function()
			assert.has.error(function()
				Text {}
			end, "expected data to be a string")

			local t = Text { data = "anything" }
			assert.equal("anything", t.data)

			assert.equal(TYPES.TEXT_NODE, t.nodeType)
		end)

	end)



	describe("properties:", function()

		it("reports proper nodeName", function()
			local t = Text { data = "anything" }
			assert.equal("#text", t.nodeName)
		end)


		it("reports proper nodeValue", function()
			local t = Text { data = "anything" }
			assert.equal("anything", t.nodeValue)
		end)

	end)



	describe("methods:", function()

		local t, doc, root
		before_each(function()
			doc = assert(DOM:createDocument("http://ns", "ns:root"))
			root = doc.documentElement
			t = assert(doc:createTextNode("anything"))
		end)



		describe("splitText()", function()

			it("returns new Text node", function()
				t.data = (valid_utf8_char.." "):rep(5)
				local t2 = t:splitText(1)
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.not_equal(t, t2)
			end)


			it("splits the text", function()
				t.data = (valid_utf8_char.." "):rep(5)
				local t2 = t:splitText(5)
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.not_equal(t, t2)
				assert.equal((valid_utf8_char.." "):rep(2), t.data)
				assert.equal((valid_utf8_char.." "):rep(3), t2.data)
			end)


			it("fails on invalid offset", function()
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					t:splitText(99)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					t:splitText(-99)
				})
				assert.same({
					nil, ERRORS.INDEX_SIZE_ERR
				}, {
					t:splitText(0)
				})
			end)


			it("split at offset = 1", function()
				t.data = (valid_utf8_char.." "):rep(5)
				local t2 = t:splitText(1)
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.not_equal(t, t2)
				assert.equal("", t.data)
				assert.equal((valid_utf8_char.." "):rep(5), t2.data)
			end)


			it("split at offset = length+1", function()
				-- TODO: length+1 allowed here, allowed everywhere? Comment node
				t.data = (valid_utf8_char.." "):rep(5)
				local t2 = assert(t:splitText(t.length+1))
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.not_equal(t, t2)
				assert.equal((valid_utf8_char.." "):rep(5), t.data)
				assert.equal("", t2.data)
			end)


			it("inserts childNode, when first node", function()
				t.data = "aabb"
				assert(root:appendChild(t))

				local elem = assert(doc:createElement("mytag"))
				assert(root:appendChild(elem))

				assert.equal(elem, t.nextSibling)
				assert.equal(2, root.childNodes.length)

				local t2 = assert(t:splitText(3))
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.equal("aa", t.data)
				assert.equal("bb", t2.data)
				assert.equal(t, t2.previousSibling)
				assert.equal(elem, t2.nextSibling)
				assert.equal(3, root.childNodes.length)
			end)


			it("inserts childNode, when last node", function()
				local elem = assert(doc:createElement("mytag"))
				assert(root:appendChild(elem))

				t.data = "aabb"
				assert(root:appendChild(t))

				assert.equal(elem, t.previousSibling)
				assert.equal(2, root.childNodes.length)

				local t2 = assert(t:splitText(3))
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.equal("aa", t.data)
				assert.equal("bb", t2.data)
				assert.equal(nil, elem.previousSibling)
				assert.equal(elem, t.previousSibling)
				assert.equal(t, t2.previousSibling)
				assert.equal(t, elem.nextSibling)
				assert.equal(t2, t.nextSibling)
				assert.equal(nil, t2.nextSibling)
				assert.equal(3, root.childNodes.length)
			end)


			it("doesn't fail if there is no parentNode", function()
				local t = assert(doc:createTextNode("mytext"))
				assert.equal(nil, t.parentNode)
				local t2 = assert(t:splitText(3))
				assert.equal(TYPES.TEXT_NODE, t2.nodeType)
				assert.equal("my", t.data)
				assert.equal("text", t2.data)
				assert.equal(nil, t.previousSibling)
				assert.equal(nil, t.nextSibling)
				assert.equal(nil, t.parentNode)
				assert.equal(nil, t2.previousSibling)
				assert.equal(nil, t2.nextSibling)
				assert.equal(nil, t2.parentNode)
			end)

		end)



		describe("write()", function()

			it("exports escaped data and returns buffer", function()
				local t = assert(doc:createTextNode("<anything>"))

				assert.same({ "&lt;anything&gt;" }, t:write({}))
			end)

		end)

	end)

end)
