## Test files

The tests here will parse a file into a DOM structure, and then write it out
again to a file.

All the files in this directory come in pairs; `*.in.xml` is the input file
being parsed. And after writing the parsed document again, the result is
compared to `*.out.xml`.

The first node after the xml declaration MUST be a Processing Instruction that
carries the description of the test.
