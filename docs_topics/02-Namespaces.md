# Namespaces

Namespaces are created using the standard methods available in the DOM Core
specification, for creating attributes and elements. See `Document.createElementNS`,
`Document.createAttributeNS`, and `Element.setAttributeNS`. A convenience method is
available for creating attributes to define a namespace; `Element:defineNamespace`.

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
Yet in the document object there will only be 2 attributes; `xmlns:lua`, and `just_attribute`
since the definition of the default namespace is reflected in the properties of the `node`
Element. It is 'implicit' in the document.

---

## Implicit and explicit namespace definitions

If the document would be parsed into a `doc` variable then;
```lua
local elem = doc.documentElement
print(elem.localName)            --> "node"
print(elem.prefix)               --> nil
print(elem.namespaceURI)         --> "default_ns"
print(elem.attributes.length)    --> 1
local source = elem.childNodes[1]
print(source.localName)          --> "source"
print(source.prefix)             --> "lua"
print(source.namespaceURI)       --> "https://lua.org"
local source = elem.childNodes[2]
print(source.localName)          --> "lua"
print(source.prefix)             --> "xmlns"
print(source.namespaceURI)       --> "http://www.w3.org/2000/xmlns/"
```
The attribute `xmlns:lua` defines the 'explicit' namespace for `'lua'`. This namespace
is implictly defined on the `'lua:source'` Element, but since it is defined ahead of
use on the `'node'` Element, it is explicit.

When writing an Xml document, the namespace attributes will implicitly be added
to the elements where they are needed. To explicitly define namespaces they can
be added as namespace definition attributes to an `Element` in the same way.

As an example, here's the same document created from code;
```lua
local DOM = require("expadom.DOMImplementation")()
doc = DOM:createDocument("default_ns", "node")
doc.documentElement:setAttribute("just_attribute", "value")
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
<node xmlns="default_ns" just_attribute="value">
    <lua:source xmlns:lua="https://lua.org">print [[hello world]]</lua:source>
</node>
```

The output however has the namespace declaration moved to the `"lua:source"`
element, since that is where it is first used. So it is defined implicitly.

If an 'explicit' declaration is added to the root element (called `"node"`), like so:
```lua
doc.documentElement:defineNamespace("https://lua.org", "lua")
print(table.concat(doc:write()))
```
Then the output becomes:
```
<?xml version="1.0" encoding="UTF-8" ?>
<node xmlns='default_ns' xmlns:lua='https://lua.org' just_attribute='value'>
    <lua:source>print [[hello world]]</lua:source>
</node>
```

---

## Caveats

When adding namespaces either explicit or implicit, there are no checks to see if they
collide with existing definitions. So it can happen that the same `prefix` has 2
different `namespaceURI`'s set. In that case, writing the document will fail with
an error.

