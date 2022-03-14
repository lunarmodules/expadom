--- XML utility functions

local constants = require "expadom.constants"
local ERRORS = constants.ERRORS
--local TYPES = constants.NODE_TYPES

local M = {}


--- Library for UTF-8 support.
-- This is either the stock Lua lib, on Lua 5.3 or higher. Or the one from
-- the Lua 5.3 compatibility module; "compat53.utf8".
-- @table utf8
M.utf8 = _G.utf8 or require("compat53.utf8")


--- splits a (qualified) name in a prefix + localname (without validation).
-- @tparam string name the tag/attribute name, with or without namespace prefix
-- @return localname, prefix. Prefix will be 'nil' if there was none
-- @usage
-- local name, prefix = split_name("clr:orange")  --> "orange", "clr"
-- local name, prefix = split_name("orange")      --> "orange", nil
function M.split_name(name)
	local nsprefix, localname = name:match("^([^:]-):?([^:]+)$")
	return localname, nsprefix ~= "" and nsprefix or nil
end

--- creates a qualified name (without validation).
-- if prefix is either empty or nil, the prefix is omitted
-- @tparam string localname the localname
-- @tparam string|nil prefix the prefix
-- @usage
-- local qualified = qualifiedname("orange", "clr")  --> "clr:orange"
-- local qualified = qualifiedname("orange", "")     --> "orange"
-- local qualified = qualifiedname("orange")         --> "orange"
function M.qualifiedname(localname, prefix)
	return (prefix ~= nil and prefix ~= "") and (prefix..":"..localname) or localname
end


--- validates a non-qualified name.
-- must be a string, at least 1 character
-- @tparam string name the tag/attribute name
-- @return name, or nil+err
function M.validate_name(name)
	if type(name) ~= "string" then
		return nil, ERRORS.INVALID_CHARACTER_ERR
	end

	if #name == 0 then
		return nil, ERRORS.NAMESPACE_ERR
	end

	-- TODO: validate characters allowed in localname

	return name
end

--- validates a prefix.
-- must be a string, can be 0 length
-- @tparam string name the prefix name
-- @return name or nil+err
function M.validate_prefix(name)
	if type(name) ~= "string" then
		return nil, ERRORS.INVALID_CHARACTER_ERR
	end

	-- TODO: validate characters allowed in localname

	return name
end

--- validates a qualified name.
-- must be a string, localname and prefix at least 1 character
-- @tparam string qualifiedName the tag/attribute name, with or without namespace prefix
-- @return localname, prefix. Prefix will be 'nil' if there was none.
function M.validate_qualifiedname(qualifiedName)
	if type(qualifiedName) ~= "string" then
		return nil, ERRORS.INVALID_CHARACTER_ERR
	end
	local prefix, localname
	local i = qualifiedName:find(":")
	if i then
		prefix = qualifiedName:sub(1, i-1)
		localname = qualifiedName:sub(i+1, -1)
		if #prefix == 0 then
			return nil, ERRORS.NAMESPACE_ERR
		end
		-- TODO: validate characters allowed in prefix
	else
		localname = qualifiedName
	end
	if #localname == 0 then
		return nil, ERRORS.NAMESPACE_ERR
	end
	-- TODO: validate characters allowed in localname

	return localname, prefix
end

--- validates a qualified name and its URI.
-- namespaceURI can be nil, if there is no prefix in the qualified name. If the prefix
-- is `xml` then the namespace must be `http://www.w3.org/XML/1998/namespace`.
-- @tparam string qualifiedName the tag/attribute name, with or without namespace prefix
-- @tparam string|nil namespaceURI the namespace uri
-- @return localname, prefix, uri, or nil+err. Prefix will be 'nil' if there was none.
function M.validate_qualifiedName_and_uri(qualifiedName, namespaceURI)
	local localname, prefix = M.validate_qualifiedname(qualifiedName)
	if not localname then
		return nil, prefix
	end

	if namespaceURI ~= nil then
		if type(namespaceURI) ~= "string" then
			return nil, ERRORS.INVALID_CHARACTER_ERR
		end
		if #namespaceURI == 0 then
			return nil, ERRORS.NAMESPACE_ERR
		end
		-- TODO: validate characters allowed in namespaceURI
	end

	if prefix and not namespaceURI then
		-- must specify a namesapce when using a prefix
		return nil, ERRORS.NAMESPACE_ERR
	end

	if prefix == "xml" and namespaceURI ~= "http://www.w3.org/XML/1998/namespace" then
		-- special prefix
		return nil, ERRORS.NAMESPACE_ERR
	end

	return localname, prefix, namespaceURI
end


do
	local escape_table = {
		["'"] = "&apos;",
		['"'] = "&quot;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;",
	}

	--- Escapes a string for safe use in xml.
	-- Handles quotes(single+double), less-than, greater-than, and ampersand.
	-- @tparam string str string value to escape
	-- @return escaped string
	-- @usage
	-- local esc = xml.xml_escape([["'<>&]])  --> "&quot;&apos;&lt;&gt;&amp;"
	function M.escape(str)
		return str:gsub("['&<>\"]", escape_table)
	end
end


return M
