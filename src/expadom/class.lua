--- Class module.
--
-- method __init will be called upon instantiation
--
-- single property:
--     readonly = boolean
--     writeonly = boolean
--     alias_to = string  --> different prop name, if this is an alias. Alias will use
--         its own get/set functions, but reads-from/writes-to other props location.
--     set = function(self, value) -- return value to set or throws a HARD error
--         self.__prop_values[prop_name] = value
--     end
--     get = function(self) -- return the value or throws a HARD error
--         return self.__prop_values[prop_name]
--     end


local Class = {}

--- Is the table a "Class".
-- Checks whether a table is a class, not any speciifc type of class, just whether
-- it is a class from this class model/system.
--
-- Since it also returns a message if not a class, it can be used in assertions.
-- @param tbl the table (or other types) to verify
-- @return true if a class, or false+error otherwise
function Class.is_class(tbl)
	if type(tbl) == "table" and
		(not tbl.__prop_values) and
		rawget(tbl, "__properties") then
		return true
	end
	return false, "not a class"
end

--- Is the table an instance of the given class.
-- Since it also returns a message, it can be used in assertions.
-- @param class the class
-- @param instance the instance to verify for being an instance of class-'class'
-- @return true if it is an instance of the class, or false+error otherwise
-- @raise if class is not a 'class'
-- @usage local Cat = Class("Cat")
-- local sylvester = Cat {name = "Sylvester"}
-- assert(Class.is_instance_of(Cat, sylvester))
function Class.is_instance_of(class, instance)
	-- TODO: also check ancestor classes
	assert(Class.is_class(class))
	if class == getmetatable(instance) then
		return true
	end
	return false, "not an instance of class " .. class.__classname
end

do
	local function get_property_prop(class, name, key)
		assert(Class.is_class(class))
		assert(type(name) == "string", "expected property name to be a string")

		local prop = class.__properties[name]
		if not prop then
			return nil, "no property by name '"..tostring(name).."'"
		end

		return prop[key]
	end

	--- returns the property-setter function.
	-- When overriding property-set functions in descendants, this can be used
	-- to fetch the original function and call it.
	-- @tparam class class a class
	-- @tparam string name the property name
	-- @return the property-set function
	-- @raise if class is not a class, or name is not a string
	function Class.get_property_set(class, name)
		return get_property_prop(class, name, "set")
	end

	--- returns the property-getter function.
	-- When overriding property-get functions in descendants, this can be used
	-- to fetch the original function and call it.
	-- @tparam class class a class
	-- @tparam string name the property name
	-- @return the property-get function
	-- @raise if class is not a class, or name is not a string
	function Class.get_property_get(class, name)
		return get_property_prop(class, name, "get")
	end

	--- returns whther the property is read-only.
	-- @tparam class class a class
	-- @tparam string name the property name
	-- @return boolean
	-- @raise if class is not a class, or name is not a string
	function Class.is_readonly(class, name)
		return get_property_prop(class, name, "readonly")
	end

	--- returns whther the property is write-only.
	-- @tparam class class a class
	-- @tparam string name the property name
	-- @return boolean
	-- @raise if class is not a class, or name is not a string
	function Class.is_writeonly(class, name)
		return get_property_prop(class, name, "writeonly")
	end
end


--- sets the property-getter function for a property of a class.
-- @tparam class class a class
-- @tparam string name the property name
-- @tparam function get the property getter function
-- @return true on success, nil+err if no property by that name exists
-- @raise if `class` is not a class, `name` is not a string, or `get` is not a function
function Class.set_property_get(class, name, get)
	assert(Class.is_class(class))
	assert(type(name) == "string", "expected name to be a string")
	assert(type(get) == "function", "expected get to be a function")

	local prop = class.__properties[name]
	if not prop then
		return nil, "no property by name '"..tostring(name).."'"
	end

	prop.get = get
	return true
end


--- sets the property-setter function for a property of a class.
-- @tparam class class a class
-- @tparam string name the property name
-- @tparam function set the property setter function
-- @return true on success, nil+err if no property by that name exists
-- @raise if `class` is not a class, `name` is not a string, or `set` is not a function
function Class.set_property_set(class, name, set)
	assert(Class.is_class(class))
	assert(type(name) == "string", "expected name to be a string")
	assert(type(set) == "function", "expected set to be a function")

	local prop = class.__properties[name]
	if not prop then
		return nil, "no property by name '"..tostring(name).."'"
	end

	prop.set = set
	return true
end


--- creates a new class.
-- @tparam string name name of the class. Will be stored in field `__classname`.
-- @tparam[opt] class ancestor the class to inherit from
-- @tparam[opt] table methods table with all methods (functions keyed by their name)
-- @tparam[opt] table properties table with properties (property tables as defined above, keyed by their name)
-- @return new class
function Class.create(name, ancestor, methods, properties)
	assert(type(name) == "string", "expected class name to be a string")
	if ancestor == nil then
		ancestor = {}
	else
		if not Class.is_class(ancestor) then
			error("expected 'ancestor' to be a class", 2)
		end
	end

	local class = {
		__classname = name,
		__properties = {},
	}

	-- add methods
	if methods == nil then
		methods = {}
	end
	assert(type(methods) == "table", "expected 'methods' to be a table")
	for method_name, method in pairs(methods) do
		assert(type(method_name) == "string", "expected method name to be a string")
		assert(type(method) == "function", "expected method to be a function")
		class[method_name] = method
	end

	-- add properties
	if properties == nil then
		properties = {}
	end
	assert(type(properties) == "table", "expected 'properties' to be a table")

	for prop_name, p in pairs(properties) do
		assert(type(prop_name) == "string", "expected property name to be a string")
		assert(type(p) == "table", "expected property value to be a table")
		local prop = {
			readonly = not not p.readonly,
			writeonly = not not p.writeonly,
		}
		class.__properties[prop_name] = prop
		if p.alias_to then
			-- this property is an alias to another property
			prop_name = p.alias_to
		end
		assert(type(prop_name) == "string", "expected property name to be a string")

		-- create setter
		local setter = p.set
		if p.readonly then
			assert(not p.writeonly, "property cannot be both readonly and writeonly")
			assert(setter == nil, "cannot pass setter for read-only property")
			prop.set = function()
				error("property '"..prop_name.."' of class '"..name.."' is read-only", 2)
			end

		elseif type(setter) == "function" then
			prop.set = setter

		elseif setter == nil then
			prop.set = function(self, value)
				self.__prop_values[prop_name] = value
			end

		else
			error("expected setter for property '"..prop_name.."' to be a function")
		end

		-- create getter
		local getter = p.get
		if p.writeonly then
			assert(getter == nil, "cannot pass getter for write-only property")
			prop.get = function()
				error("property '"..prop_name.."' of class '"..name.."' is write-only", 2)
			end

		elseif type(getter) == "function" then
			prop.get = getter

		elseif getter == nil then
			prop.get = function(self)
				return self.__prop_values[prop_name]
			end

		else
			error("expected getter for property '"..prop_name.."' to be a function")
		end
	end

	-- copy ancestor methods
	for k, v in pairs(ancestor) do
		if class[k] == nil and class.__properties[k] == nil then
			class[k] = v
		end
	end
	-- copy ancestor properties
	for k, v in pairs(ancestor.__properties or {}) do
		if class[k] == nil and class.__properties[k] == nil then
			class.__properties[k] = v
		end
	end

	function class:__newindex(key, value)
		-- __newindex invoked when setting a value on an INSTANCE!
		local prop = class.__properties[key]
		if not prop then
			-- no property defined, just set it on the instance
			rawset(self, key, value)
		else
			-- call property setter
			prop.set(self, value)
		end
	end

	function class:__index(key)
		-- __index invoked when getting a non-existing value from an INSTANCE!
		local prop = class.__properties[key]
		if prop then
			-- call property getter
			return prop.get(self)
		end

		-- look up in ancestor class, and lazy-copy it over to the instance
		local val = class[key]
		if val then
			rawset(self, key, val)
			return val
		end
	end


	setmetatable(class, {
		__call = function(self, instance)
			-- __call invoked when calling on the CLASS, creating a new INSTANCE
			if instance == nil then
				instance = {}
			end
			assert(type(instance) == "table", "expected instance to be a table")

			-- move property values into the property tracking table, and remove
			-- them from the instance. This will BYPASS the "setters" !!
			instance.__prop_values = {}
			for prop_name in pairs(class.__properties) do
				local value = instance[prop_name]
				if value ~= nil then
					instance[prop_name] = nil
					instance.__prop_values[prop_name] = value
				end
			end

			-- make it an instance, activating setters/getters
			setmetatable(instance, self)

			-- call constructor
			if instance.__init then
				local ok, err = instance:__init()
				if not ok then
					error("failed to instantiate `"..tostring(self.__classname).."`, __init failed: " .. tostring(err))
				end
			end

			return instance
		end
	})
	return class
end

return setmetatable(Class, {
	__call = function(self, ...)
		return self.create(...)
	end
})
