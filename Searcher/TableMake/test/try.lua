local TableMake = require "Searcher.TableMake"

local tm = TableMake:new()

tm:add_kind{
   name = "trytest",
   { "first", "number" },
   { "second", "string", searchable=true },
   key_self = {{"tags", "trytest_tags", searchable=true}}
}

tm:add_kind{
   name = "trytest_tags",
   {"from_id", "ref", "trytest", keyed=true},
   {"key", "string", keyed=true, searchable=true}
}

tm:insert{kind="trytest", first=1, second="second two"}
tm:insert{kind="trytest", first=1, second="two", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="two sec", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="not here", tags={sec_but_here={}, another={}}}

for _, el in ipairs(tm:filter{"search", "sec", in_kind="trytest"}) do
   for k,v in pairs(el) do print("f", k,v) end
end

local filter_lua = require("Searcher.TableMake.filter").filter_lua

print(filter_lua(tm.kinds.trytest, {"search", "sec", in_kind="trytest"}))
