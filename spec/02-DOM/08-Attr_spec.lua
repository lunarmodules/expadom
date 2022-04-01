describe("Attr:", function()

	local ERRORS = require("expadom.constants").ERRORS
	local Attribute = require "expadom.Attr"

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

		local cases = {
		{
			desc = "simple name",
			input = {
				name = "abc"
			},
			output = {
				name = "abc",
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
				name = "ns:abc",
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
				name = "abc",
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
				name = "ns:abc",
				qualifiedName = "ns:abc",
				namespaceURI = "http://ns",
				prefix = "ns",
				localName = "abc",
				nodeName = "ns:abc",
			}
		}, {
			desc = "nothing specified",
			input = {},
			error = "failed to instantiate `Attribute`, __init failed: at least name, localName or qualifiedName must be given",
		}, {
			desc = "qualifiedName and name",
			input = {
				qualifiedName = "abc",
				name = "abc"
			},
			error = "failed to instantiate `Attribute`, __init failed: name, localName, and prefix must be nil if qualifiedName is given",
		}, {
			desc = "qualifiedName and localName",
			input = {
				qualifiedName = "ns:abc",
				localName = "abc"
			},
			error = "failed to instantiate `Attribute`, __init failed: name, localName, and prefix must be nil if qualifiedName is given",
		}, {
			desc = "qualifiedName and prefix",
			input = {
				qualifiedName = "ns:abc",
				prefix = "ns"
			},
			error = "failed to instantiate `Attribute`, __init failed: name, localName, and prefix must be nil if qualifiedName is given",
		}, {
			desc = "qualifiedName (without prefix) and namespaceURI requires a prefix",
			input = {
				qualifiedName = "abc",
				namespaceURI = "http://ns",
			},
			error = "failed to instantiate `Attribute`, __init failed: attribute must have a prefix if namespaceURI is given",
			-- output = {
			-- 	name = "abc",
			-- 	qualifiedName = "abc",
			-- 	namespaceURI = "http://ns",
			-- 	prefix = nil,
			-- 	localName = "abc",
			-- 	nodeName = "abc"
			-- }
		}, {
			desc = "qualifiedName (without prefix) and NO namespaceURI result in simple/level 1",
			input = {
				qualifiedName = "abc",
			},
			output = {
				name = "abc",
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
				name = "abc"
			},
			error = "failed to instantiate `Attribute`, __init failed: cannot specify both name and localName",
		}, {
			desc = "name and prefix",
			input = {
				prefix = "ns",
				name = "abc"
			},
			error = "failed to instantiate `Attribute`, __init failed: cannot specify namespace attributes (prefix or namespaceURI) with simple DOM level 1 name",
		}, {
			desc = "name and namespaceURI",
			input = {
				namespaceURI = "http://ns",
				name = "abc"
			},
			error = "failed to instantiate `Attribute`, __init failed: cannot specify namespace attributes (prefix or namespaceURI) with simple DOM level 1 name",
		}, {
			desc = "localName, prefix without namespaceURI",
			input = {
				localName = "abc",
				prefix = "ns",
			},
			error = "failed to instantiate `Attribute`, __init failed: namespaceURI is required when specifying a prefix",
		}, {
			desc = "prefix 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'",
			input = {
				qualifiedName = "xml:abc",
				namespaceURI = "http://www.w3.org/XML/1998/namespace",
			},
			output = {
				name = "xml:abc",
				qualifiedName = "xml:abc",
				namespaceURI = "http://www.w3.org/XML/1998/namespace",
				prefix = "xml",
				localName = "abc",
				nodeName = "xml:abc"
			}
		}, {
			desc = "qualifiedName 'xmlns' with namespace 'http://www.w3.org/2000/xmlns/'",
			input = {
				qualifiedName = "xmlns",
				namespaceURI = "http://www.w3.org/2000/xmlns/",
			},
			output = {
				name = "xmlns",
				qualifiedName = "xmlns",
				namespaceURI = "http://www.w3.org/2000/xmlns/",
				prefix = nil,
				localName = "xmlns",
				nodeName = "xmlns"
			}
		}, {
			desc = "localName 'xmlns' with namespace 'http://www.w3.org/2000/xmlns/'",
			input = {
				localName = "xmlns",
				namespaceURI = "http://www.w3.org/2000/xmlns/",
			},
			output = {
				name = "xmlns",
				qualifiedName = "xmlns",
				namespaceURI = "http://www.w3.org/2000/xmlns/",
				prefix = nil,
				localName = "xmlns",
				nodeName = "xmlns"
			}
		}, {
			desc = "prefix 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'",
			input = {
				qualifiedName = "xml:abc",
				namespaceURI = "http://ns",
			},
			error = "failed to instantiate `Attribute`, __init failed: prefix 'xml' is reserved for namespace 'http://www.w3.org/XML/1998/namespace'"
		}}

		for i, case in ipairs(cases) do
			it((case.error and "fail: " or "success: ")..case.desc, function()
				if case.error then
					assert.has.error(function()
						Attribute(case.input)
					end, case.error)
				else
					local attr, err
					assert.has.no.error(function()
						attr, err = Attribute(case.input)
					end)
					assert.equal(nil, err)
					assert.equal(case.output.name, attr.name)
					assert.equal(case.output.qualifiedName, attr.qualifiedName)
					assert.equal(case.output.namespaceURI, attr.namespaceURI)
					assert.equal(case.output.localName, attr.localName)
					assert.equal(case.output.prefix, attr.prefix)
				end
			end)
		end

	end)



	describe("properties:", function()

		describe("value", function()

			it("validates data set", function()
				local attr = Attribute { name = "myattr" }
				assert.has.error(function()
					attr.value = invalid_utf8
				end, ERRORS.INVALID_CHARACTER_ERR)
			end)

			it("also sets the nodeValue", function()
				local attr = Attribute { name = "myattr" }
				attr.value = "a value"
				assert.equal("a value", attr.value)
				assert.equal("a value", attr.nodeValue)
			end)


			it("fails when setting non-strings", function()
				local attr = Attribute { name = "myattr" }
				assert.has.error(function()
					attr.value = 123
				end, "expected value to be a sting")
			end)

		end)


		describe("prefix:", function()

			it("setting 'xml' requires namespace 'http://www.w3.org/XML/1998/namespace'", function()
				local node = Attribute {
					namespaceURI = "http://www.w3.org/XML/1998/namespace",
					qualifiedName = "ns:tagname",
				}
				assert.has.no.error(function()
					node.prefix = "xml"
				end)

				local node = Attribute {
					namespaceURI = "http://ns",
					qualifiedName = "ns:tagname",
				}
				assert.has.error(function()
					node.prefix = "xml"
				end, ERRORS.NAMESPACE_ERR)
			end)


			it("setting 'xmlns' requires namespace 'http://www.w3.org/2000/xmlns/'", function()
				local node = Attribute {
					namespaceURI = "http://www.w3.org/2000/xmlns/",
					qualifiedName = "prefix:tagname",
				}
				assert.has.no.error(function()
					node.prefix = "xmlns"
				end)

				local node = Attribute {
					namespaceURI = "http://ns",
					qualifiedName = "prefix:tagname",
				}
				assert.has.error(function()
					node.prefix = "xmlns"
				end, ERRORS.NAMESPACE_ERR)
			end)


			it("setting 'nil' fails if there is a namespaceUri", function()
				local node = Attribute {
					namespaceURI = "http://ns",
					qualifiedName = "prefix:tagname",
				}
				assert.has.error(function()
					node.prefix = nil
				end, ERRORS.NAMESPACE_ERR)
			end)

		end)


		it("reports proper nodeName", function()
			local attr = Attribute { name = "myattr" }
			assert.equal("myattr", attr.nodeName)
		end)


		it("reports proper nodeValue", function()
			local attr = Attribute { name = "myattr" }
			attr.value = "a value"
			assert.equal("a value", attr.nodeValue)
		end)

	end)



	describe("methods:", function()

		describe("write()", function()

			it("exports escaped data and returns buffer", function()
				local attr = Attribute {
					name = "myattr"
				}
				attr.value = "a 'value'"
				assert.equal([[ myattr="a &apos;value&apos;"]], table.concat(attr:write {}))
			end)


			it("exports escaped data and returns buffer with namespace", function()
				local attr = Attribute {
					namespaceURI = "http://ns",
					qualifiedName = "prefix:tagname",
				}
				attr.value = "a 'value'"
				assert.equal([[ prefix:tagname="a &apos;value&apos;"]], table.concat(attr:write {}))
			end)


			it("exports an empty attribute", function()
				local attr = Attribute {
					name = "myattr"
				}
				assert.equal([[ myattr=""]], table.concat(attr:write {}))
			end)

		end)

	end)

end)
