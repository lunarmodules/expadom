# expadom

[![Build](https://img.shields.io/github/workflow/status/lunarmodules/expadom/Build?label=Test%20suite&logo=lua)](https://github.com/lunarmodules/expadom/actions)
[![Luacheck](https://img.shields.io/github/workflow/status/lunarmodules/expadom/Luacheck?label=Luacheck&logo=lua)](https://github.com/lunarmodules/expadom/actions)
[![Coveralls code coverage](https://img.shields.io/coveralls/github/lunarmodules/expadom?label=Coverage&logo=coveralls)](https://coveralls.io/github/lunarmodules/expadom)
[![SemVer](https://img.shields.io/github/v/tag/lunarmodules/expadom?color=brightgreen&label=SemVer&logo=semver&sort=semver)](#history)
[![License](https://img.shields.io/github/license/lunarmodules/expadom.svg?label=License)](https://github.com/Kong/insomnia/blob/master/LICENSE)

An [XML DOM Level 2](https://www.w3.org/TR/DOM-Level-2-Core/) implementation in Lua,
based on the [(Lua)Expat parser](https://github.com/lunarmodules/luaexpat).

## Synopsis

```lua
local DOM = require("expadom.DOMImplementation")()
local doc = DOM:createDocument(nil, "root")
local root = doc.documentElement
root:appendChild(doc:createComment("let's create an address list"))
local list = doc:createElement("addresses")
list:setAttribute("country", "Netherlands")
root:appendChild(list)
local addr = doc:createElement("address")
list:appendChild(addr)
addr:appendChild(doc:createTextNode("address goes here"))

local xml_written = table.concat(doc:write())

-- result (formatting added for readability):
-- <?xml version="1.0" encoding="UTF-8"?>
-- <root>
--     <!--let's create an address list-->
--     <addresses country="Netherlands">
--         <address>address goes here</address>
--     </addresses>
-- </root>

-- now parse the document again:
local xml_parsed = require("expadom").parseDocument(xml_written)
local address = xml_parsed:getElementsByTagName("address")[1]
print(address.childNodes[1].nodeValue)  --> "address goes here"
```

## Getting started

### Parsing documents

To parse documents start with the main [`expadom` module](https://lunarmodules.github.io/expadom/modules/expadom.html);

```lua
local parseXml = require("expadom").parseDocument
local doc = parseXml("<root>hello world</root>")
```

### Creating documents

To create documents use the [DOMImplementation](https://lunarmodules.github.io/expadom/classes/DOMImplementation.html)
to create a Document. From there the [Document interface](https://lunarmodules.github.io/expadom/classes/Document.html)
can be used to create all sorts of children and build the document;

```lua
local DOM = require("expadom.DOMImplementation")()
local doc = DOM:createDocument(nil, "root")
local root = doc.documentElement
root:appendChild(doc:createTextNode("hello world"))
```

## Good to know

* This is a Lua implementation, so any 0-based indices mentioned in the DOM Level
  2 specification will be 1-based in this implementation.
* The spec defines "dynamic", and readonly properties, like `Node.nextSibling` for
  example. In Lua traditionally properties are static fields on a table. This
  implementation however stays close to the spec, and has dynamic properties,
  although this is not very 'lua-ish'.
* The only supported encoding is UTF-8. The underlying Expat parser will convert
  the other common ones to UTF-8, so parsing is covered. But generated output will
  only be UTF-8.
* DTD's are not supported, neither external nor internal subsets.

## Downloads, dependencies, and source code

Source ode and downloads are available from the [Github project page](https://github.com/lunarmodules/expadom). Installation is typically easiest using LuaRocks.

### Dependencies

Expadom depends on the following packages:
* [LuaExpat](https://github.com/lunarmodules/luaexpat) for parsing XML. This requires
  that [Expat](https://github.com/libexpat/libexpat) itself is also installed.
* The Lua module [compat53](https://github.com/keplerproject/lua-compat-5.3) is required
  for UTF-8 support on Lua versions lacking the `utf8` module (pre Lua 5.3).

When installing through LuaRocks, `Expat` must be installed manually, the other
dependencies will be dealt with by LuaRocks.

## License & Copyright

The project is licensed under the [MIT License](https://github.com/lunarmodules/expadom/blob/main/LICENSE)

## History

none...
