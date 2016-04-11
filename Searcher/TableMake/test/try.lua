local TableMake = require "Searcher.TableMake"

local tm = TableMake:new()

tm:add_kind{
   name = "trytest",
   { "first", "number" },
   { "second", "string" },
   key_self = {{"tags", "trytest_tags"}}
}

tm:add_kind{
   name = "trytest_tags",
   {"from_id", "ref", "trytest"},--, keyed=true},
   {"key", "string"},--, keyed=true}
}

tm:insert{kind="trytest", first=1, second="two"}
tm:insert{kind="trytest", first=1, second="two", tags={has_a_tag={}, another={}}}

for _, el in ipairs(tm.db:exec("SELECT * FROM tm_trytest;")) do
   for k,v in pairs(el) do print(k,v) end
end
-- for _, el in ipairs(tm.db:exec("SELECT * FROM tm_trytest_tags")) do
--    for k,v in pairs(el) do print(k,v) end
-- end
--for _, el in ipairs(tm:filter{"sql_like", "second", "%", in_kind="trytest"}) do
--   for k,v in pairs(el) do print("f", k,v) end
--end

