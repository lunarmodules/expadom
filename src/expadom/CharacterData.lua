--- XML DOM CharacterData Interface.
--
-- The [CharacterData](https://www.w3.org/TR/DOM-Level-2-Core/#core-ID-FF21A306)
-- interface. The actual implementation lives in the `Comment` class.
--
-- The characterdata does not have its own node-type in DOM2 specs, hence we
-- simply use the `Comment` class, since that class inherits from CharacterData,
-- but doesn't add anything.
--
-- @classmod CharacterData

return require "expadom.Comment"
