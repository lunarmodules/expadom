# expadom

An [XML DOM Level 2 Core](https://www.w3.org/TR/DOM-Level-2-Core/) implementation in Lua
(with some Level 3 additions),
based on the [(Lua)Expat parser](https://github.com/lunarmodules/luaexpat).

## Parsing documents

To parse documents start with the main [`expadom` module](https://lunarmodules.github.io/expadom/modules/expadom.html);

```lua
local parseXml = require("expadom").parseDocument
local doc = parseXml("<root>hello world</root>")
```

## Creating documents

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

* Namespaces are tracked on a per Node basis, not in Attributes, see `Namespaces`.
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
