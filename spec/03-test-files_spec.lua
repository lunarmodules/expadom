local concat = table.concat

describe("test-files", function()

	local TYPES = require("expadom.constants").NODE_TYPES
	local getfiles = require("pl.dir").getfiles
	local files = getfiles("./spec/03-test-files", "*.in.xml")
	table.sort(files)
	local readfile = require("pl.utils").readfile
	local basename = require("pl.path").basename
	local expadom = require "expadom"

	for _, inFile in ipairs(files) do
		local outFile = inFile:gsub("%.in%.xml", ".out.xml")
		local inXml = readfile(inFile)
		local outXml = assert(readfile(outFile))
		local doc = assert(expadom.parseDocument(inXml))
		local descriptionPI = doc.childNodes[1]
		assert(descriptionPI.nodeType == TYPES.PROCESSING_INSTRUCTION_NODE,
			inFile..": Expected the first element in the xml document to be a ProcessingInstruction with the test description")


		it("(".. basename(inFile).." whole) "..descriptionPI.data, function()
			assert.same(outXml, concat(doc:write {}))
		end)


		it("(".. basename(inFile).." chunked) "..descriptionPI.data, function()
			local parser = assert(expadom.createParser())
			for i = 1, #inXml do
				assert(parser:parse(inXml:sub(i,i)))
			end
			doc = assert(expadom.closeParser(parser))
			assert.same(outXml, concat(doc:write {}))
		end)

	end

end)
