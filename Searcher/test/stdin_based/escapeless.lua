local escapeless = require "Searcher.escapeless"

local fd = io.open("/dev/stdin")

local data = fd:read("*a")
local ed = escapeless.enc(data)

print(ed)
assert( string.find(ed, "^[%p%w%d%s]*$") )

local got = escapeless.dec(ed)
assert( data == got, string.format("WRONG\nenc:%s\npre:%s\naft:%s", ed, data, got))
