--- Constants for the DOM implementation.


-- Function copied from the Penlight module 'pl.utils'
-- https://github.com/lunarmodules/Penlight
local function enum(...)
	local first = select(1, ...)
	local enum = {}
	local lst

	if type(first) ~= "table" then
		-- vararg with strings
		lst = { n = select("#", ...), ...}
		for i = 1, lst.n do
			local value = lst[i]
			if type(value) ~= "string" then
				error(string.format("expected argument %d to be a string, got %s", i, type(value)))
			end
			enum[value] = value
		end

	else
		-- table/array with values
		if type(first) ~= "table" then
			error(string.format("expected argument 1 to be a table, got %s", type(first)))
		end

		lst = {}
		-- first add array part
		for i, value in ipairs(first) do
			if type(value) ~= "string" then
				error(("expected 'string' but got '%s' at index %d"):format(type(value), i), 2)
			end
			lst[i] = value
			enum[value] = value
		end
		-- add key-ed part
		for key, value in pairs(first) do
			if type(key) ~= "number" or math.floor(key) ~= key then
				if type(key) ~= "string" then
					error(("expected key to be 'string' but got '%s'"):format(type(key)), 2)
				end
				if enum[key] then
					error(("duplicate entry in array and hash part: '%s'"):format(key), 2)
				end
				enum[key] = value
				lst[#lst+1] = key
			end
		end
	end

	if not lst[1] then
		error("expected at least 1 entry", 2)
	end

	local valid = "(expected one of: '" .. table.concat(lst, "', '") .. "')"
	setmetatable(enum, {
		__index = function(self, key)
			error(("'%s' is not a valid value %s"):format(tostring(key), valid), 2)
		end,
		__newindex = function(self, key, value)
			error("the Enum object is read-only", 2)
		end,
		__call = function(self, key)
			if type(key) == "string" then
				local v = rawget(self, key)
				if v ~= nil then
					return v
				end
			end
			return nil, ("'%s' is not a valid value %s"):format(tostring(key), valid)
		end
	})

	return enum
end


---
-- @field DEFAULT_NS_KEY the 'prefix' value to use to indicate the default namespace, see `Element:write`.
-- @field ERRORS Error return codes [as defined here](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-17189187)
-- @field NODE_TYPES Node types [as defined here](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-1950641247)
-- @field DEFAULT_NAMESPACES hash table with entries; `xmlns = "http://www.w3.org/2000/xmlns/"`, and `xml = "http://www.w3.org/XML/1998/namespace"`
-- @table constants
local constants = enum {
	DEFAULT_NS_KEY = "_default",
	NIL_SENTINEL = {},
	DEFAULT_NAMESPACES = setmetatable({
		xml = "http://www.w3.org/XML/1998/namespace",
		xmlns = "http://www.w3.org/2000/xmlns/",
	},{
		__newindex = function() error("DEFAULT_NAMESPACES is a read-only table") end,
	}),

	ERRORS = enum {
		-- level 1
		INDEX_SIZE_ERR = 1,
		DOMSTRING_SIZE_ERR = 2,
		HIERARCHY_REQUEST_ERR = 3,
		WRONG_DOCUMENT_ERR = 4,
		INVALID_CHARACTER_ERR = 5,
		NO_DATA_ALLOWED_ERR = 6,
		NO_MODIFICATION_ALLOWED_ERR = 7,
		NOT_FOUND_ERR = 8,
		NOT_SUPPORTED_ERR = 9,
		INUSE_ATTRIBUTE_ERR = 10,
		-- level 2 additions
		INVALID_STATE_ERR = 11,
		SYNTAX_ERR = 12,
		INVALID_MODIFICATION_ERR = 13,
		NAMESPACE_ERR = 14,
		INVALID_ACCESS_ERR = 15,
	},

	NODE_TYPES = enum {
		ELEMENT_NODE = 1,
		ATTRIBUTE_NODE = 2,
		TEXT_NODE = 3,
		CDATA_SECTION_NODE = 4,
		ENTITY_REFERENCE_NODE = 5,
		ENTITY_NODE = 6,
		PROCESSING_INSTRUCTION_NODE = 7,
		COMMENT_NODE = 8,
		DOCUMENT_NODE = 9,
		DOCUMENT_TYPE_NODE = 10,
		DOCUMENT_FRAGMENT_NODE = 11,
		NOTATION_NODE = 12,
	},
}

return constants
