describe("Class", function()

	local Class

	before_each(function()
		Class = require "expadom.class"
	end)

	describe("Class()", function()

		it("creates a base class", function()
			local Cat = Class("Cat")
			assert.is.table(Cat)
			assert.is.same({}, Cat.__properties)
			assert.equal("Cat", Cat.__classname)
		end)


		it("adds methods", function()
			local meow = function() end
			local Cat = Class("Cat", nil, { meow = meow })
			assert.is.table(Cat)
			assert.is.same({}, Cat.__properties)
			assert.equal("Cat", Cat.__classname)
			assert.equal(Cat.meow, meow)
		end)


		it("adds properties", function()
			local properties = {
				fur = {
					readonly = false,
					writeonly = false,
					get = function(self)
						return self.__prop_values.fur .. " by getter"
					end,
					set = function(self, value)
						return value .. " by setter"
					end,
				}
			}
			local Cat = Class("Cat", nil, nil, properties)
			assert.is.table(Cat)
			assert.is.table(Cat.__properties)
			assert.is.table(Cat.__properties.fur)
			assert.is.False(Cat.__properties.fur.readonly)
			assert.is.False(Cat.__properties.fur.writeonly)
			assert.equal("Cat", Cat.__classname)
		end)


		it("instance basics work", function()
			local ok
			local properties = {
				fur = {
					readonly = false,
					writeonly = false,
					get = function(self)
						return tostring(self.__prop_values.fur) .. " by getter"
					end,
					set = function(self, value)
						self.__prop_values.fur = tostring(value) .. " by setter"
					end
				}
			}
			local methods = {
				meow = function(self)
					ok = self
				end
			}
			local Cat = Class("Cat", nil, methods, properties)
			local pussycat = Cat()

			assert.is.table(pussycat.__prop_values)

			pussycat:meow()
			assert.equal(pussycat, ok)

			assert.equal("nil by getter", pussycat.fur)
			pussycat.fur = "hair"
			assert.equal("hair by setter by getter", pussycat.fur)
		end)

	end)



	describe("is_class()", function()

		it("tests whether something is a class", function()
			local Cat = Class("Cat")
			assert.same({true, nil}, {Class.is_class(Cat)})
			local Lion = Class("Lion", Cat)
			assert.same({true, nil}, {Class.is_class(Lion)})

			assert.same({false, "not a class"}, {Class.is_class({})})
			assert.same({false, "not a class"}, {Class.is_class(123)})
		end)

	end)



	describe("is_instance_of()", function()

		it("tests whether something is a class", function()
			local Cat = Class("Cat")
			assert.same({true, nil}, {Class.is_instance_of(Cat, Cat())})
			local Lion = Class("Lion", Cat)
			assert.same({true, nil}, {Class.is_instance_of(Lion, Lion())})

			assert.same({false, "not an instance of class Cat"}, {Class.is_instance_of(Cat, {})})
			assert.same({false, "not an instance of class Lion"}, {Class.is_instance_of(Lion, {})})
		end)

		it("errors if class is not a class", function()
			assert.has.error(function()
				Class.is_instance_of({}, {})
			end, "not a class")
		end)

	end)



	describe("get_property_get()/set()", function()

		local Cat, getter, setter

		before_each(function()
			getter = function(self)
				return self.__prop_values.sound
			end

			setter = function(self, value)
				self.__prop_values.sound = value
			end

			Cat = Class("Cat", nil, nil, {
				sound = {
					get = getter,
					set = setter,
				}
			})
		end)



		it("gets the (g/s)etter", function()
			assert.equal(getter, Class.get_property_get(Cat, "sound"))
			assert.equal(setter, Class.get_property_set(Cat, "sound"))
		end)

	end)


end)
