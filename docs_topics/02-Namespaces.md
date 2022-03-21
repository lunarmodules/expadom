# Namespaces

Namesapces are created using the standard methods available in the DOM Core
specification, for creating attributes and elements. See `Document.createElementNS`,
`Document.createAttributeNS`, and `Element.setAttributeNS`.

In this Lua implementation the `namespaceURI`, `localName`, and `prefix` properties
are tracked on the Nodes. Not in Attribute nodes in Elements. This means that there
will be no attributes in the document tree for defining namespaces.

Example with 2 namespaces defined on the root element:
```
<node xmlns='default_ns' xmlns:lua='https://lua.org' just_attribute='value'>
    <lua:source>print [[hello world]]</lua:source>
</node>
```

The top-level `"node"` element defines 3 attributes, of which 2 are namespace declarations.
Yet in the document object there will only be 1 attribute; `just_attribute` since
the definitions are reflected in the properties of the nodes.

If the document would be parsed into a `doc` variable then;
```lua
local elem = doc.documentElement
print(elem.localName)            --> "node"
print(elem.prefix)               --> nil
print(elem.namespaceURI)         --> "default_ns"
print(elem.attributes.length)    --> 1
local source = elem.childNodes[2]
print(source.localName)          --> "source"
print(source.prefix)             --> lua
print(source.namespaceURI)       --> "https://lua.org"
```

When writing an Xml document, the namespace attributes will implicitly be added
to the elements where they are needed. To explicitly define namespaces they can
be added to `explicitNamespaces` in `Element.properties`.

As an example, here's the same document ceated from code;
```lua
local DOM = require("expadom.DOMImplementation")()
doc = DOM:createDocument("default_ns", "node")
local source = doc:createElementNS("https://lua.org", "lua:source")
doc.documentElement:appendChild(doc:createTextNode("\n    "))
doc.documentElement:appendChild(source)
doc.documentElement:appendChild(doc:createTextNode("\n"))
source:appendChild(doc:createTextNode("print [[hello world]]"))
print(table.concat(doc:write()))
```
Output:
```
<?xml version="1.0" encoding="UTF-8" ?>
<node xmlns="default_ns">
    <lua:source xmlns:lua="https://lua.org">print [[hello world]]</lua:source>
</node>
```

The output however has the namespace declaration moved to the `"lua:source"`
element, since that is where it is first used.

If an explicit declaration is added to the root element (called `"node"`), like so:
```lua
doc.documentElement.explicitNamespaces["lua"] = "https://lua.org"
print(table.concat(doc:write()))
```
Then the output becomes:
```
<?xml version="1.0" encoding="UTF-8" ?>
<node xmlns:lua="https://lua.org" xmlns="default_ns">
    <lua:source>print [[hello world]]</lua:source>
</node>
```
