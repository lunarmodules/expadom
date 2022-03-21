describe("xmlutils", function()

	local utils, ERRORS

	before_each(function()
		utils = require("expadom.xmlutils")
		ERRORS = require("expadom.constants").ERRORS
	end)


	describe("split_name()", function()

		it("splits into prefix and localname", function()
			assert.same({"name","ns"}, {utils.split_name("ns:name")})
			assert.same({"name"     }, {utils.split_name("name")})
			-- does no validation, so any other input is undefined
		end)

	end)



	describe("qualifiedname()", function()

		it("combines prefix and localname", function()
			assert.same("ns:name", utils.qualifiedname("name", "ns"))
			assert.same("name", utils.qualifiedname("name", ""))
			assert.same("name", utils.qualifiedname("name"))
			-- does no validation, so any other input is undefined
		end)

	end)



	describe("validate_name()", function()

		it("validates proper names", function()
			assert.same({"name", nil}, {utils.validate_name("name")})
		end)


		it("returns errors on bad input", function()
			local name, err
			name, err = utils.validate_name(123)
			assert.equal(ERRORS.INVALID_CHARACTER_ERR, err)
			assert.equal(nil, name)

			name, err = utils.validate_name("")
			assert.equal(ERRORS.NAMESPACE_ERR, err)
			assert.equal(nil, name)
		end)


		pending("validates valid characters", function()
			-- TODO: implement
			-- valid UTF8, and only allowed characters for name/prefix
		end)

	end)



	describe("validate_qualifiedname()", function()

		it("splits into prefix and localname", function()
			assert.same({"name","ns"}, {utils.validate_qualifiedname("ns:name")})
			assert.same({"name"     }, {utils.validate_qualifiedname("name")})
		end)


		it("returns errors on bad input", function()
			local name, prefix
			name, prefix = utils.validate_qualifiedname(123)
			assert.equal(ERRORS.INVALID_CHARACTER_ERR, prefix)
			assert.equal(nil, name)

			name, prefix = utils.validate_qualifiedname(":name")
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)

			name, prefix = utils.validate_qualifiedname("ns:")
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)

			name, prefix = utils.validate_qualifiedname(":")
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)
		end)


		pending("validates valid characters", function()
			-- TODO: implement
			-- valid UTF8, and only allowed characters for name/prefix
		end)

	end)



	describe("validate_qualifiedName_and_uri()", function()

		local xml_ns = "http://www.w3.org/XML/1998/namespace"
		local ns = "http://some/test/uri"

		it("splits into prefix, localname, uri", function()
			assert.same({"name", "ns", ns}, {utils.validate_qualifiedName_and_uri("ns:name", ns)})
			assert.same({"name", nil,  ns}, {utils.validate_qualifiedName_and_uri("name", ns)})
			assert.same({"name", "xml",  xml_ns}, {utils.validate_qualifiedName_and_uri("xml:name", xml_ns)})
		end)


		it("returns errors on bad input", function()
			local name, prefix, uri
			name, prefix, uri = utils.validate_qualifiedName_and_uri(123, ns)
			assert.equal(ERRORS.INVALID_CHARACTER_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)

			name, prefix, uri = utils.validate_qualifiedName_and_uri(":name", ns)
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)

			name, prefix, uri = utils.validate_qualifiedName_and_uri("ns:", ns)
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)

			name, prefix, uri = utils.validate_qualifiedName_and_uri(":", ns)
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)

			name, prefix, uri = utils.validate_qualifiedName_and_uri("ns:name", 123)
			assert.equal(ERRORS.INVALID_CHARACTER_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)

			name, prefix, uri = utils.validate_qualifiedName_and_uri("xml:name", ns)
			assert.equal(ERRORS.NAMESPACE_ERR, prefix)
			assert.equal(nil, name)
			assert.equal(nil, uri)
		end)


		pending("validates valid characters", function()
			-- TODO: implement
			-- valid UTF8, and only allowed characters for name/prefix/uri
		end)

	end)

end)
