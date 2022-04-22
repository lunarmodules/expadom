# expadom

[![Build](https://img.shields.io/github/workflow/status/lunarmodules/expadom/Build?label=Test%20suite&logo=lua)](https://github.com/lunarmodules/expadom/actions)
[![Luacheck](https://img.shields.io/github/workflow/status/lunarmodules/expadom/Luacheck?label=Luacheck&logo=lua)](https://github.com/lunarmodules/expadom/actions)
[![Coveralls code coverage](https://img.shields.io/coveralls/github/lunarmodules/expadom?label=Coverage&logo=coveralls)](https://coveralls.io/github/lunarmodules/expadom)
[![SemVer](https://img.shields.io/github/v/tag/lunarmodules/expadom?color=brightgreen&label=SemVer&logo=semver&sort=semver)](#history)
[![License](https://img.shields.io/github/license/lunarmodules/expadom.svg?label=License)](https://github.com/Kong/insomnia/blob/master/LICENSE)

An [XML DOM Level 2 Core](https://www.w3.org/TR/DOM-Level-2-Core/) implementation in Lua,
based on the [(Lua)Expat parser](https://github.com/lunarmodules/luaexpat).

## Status

This library is under early development and does not have everything implemented
yet. Scan the code for `"TODO:"` to see what is still to be done.

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

## Documentation

[The documentation and reference](https://lunarmodules.github.io/expadom/topics/01-Introduction.md.html) is available in the `/docs` folder, and online.

## Downloads, dependencies, and source code

Source code and downloads are available from the [Github project page](https://github.com/lunarmodules/expadom). Installation is typically easiest using LuaRocks.

### Dependencies

Expadom depends on the following packages:

* [LuaExpat](https://github.com/lunarmodules/luaexpat) for parsing XML. This requires
  that [libexpat](https://github.com/libexpat/libexpat) itself is also installed.
* The Lua module [compat53](https://github.com/keplerproject/lua-compat-5.3) is required
  for UTF-8 support on Lua versions lacking the `utf8` module (pre Lua 5.3).

When installing through LuaRocks, `libexpat` must be installed manually, the other
dependencies will be dealt with by LuaRocks.

## License & Copyright

The project is licensed under the [MIT License](https://github.com/lunarmodules/expadom/blob/main/LICENSE)

## History

#### 22-Apr-2022 0.1.0 Initial release

* Most of the DOM level 2 has been implemented
