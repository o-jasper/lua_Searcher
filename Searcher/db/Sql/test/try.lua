local TableMake = require "Searcher.db.Sql"

local tm = TableMake:new()

tm:add_kind{
   name = "trytest",
   { "first", "number" },
   { "second", "string", searchable=true },
   {"tags", "set", "trytest_tags", searchable=true}
}

tm:add_kind{
   name = "trytest_tags",
   -- TODO this does not allow for arbitrary graphs. Kinds can only go down tree-style.
   --  Perhaps the specification approach should reflect that.
   {"from_id", "ref", "trytest", keyed=true},
   {"key", "string", keyed=true, searchable=true}
}

tm:insert{kind="trytest", first=1, second="ska two"}
tm:insert{kind="trytest", first=1, second="two", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="two ska", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="not here", tags={ska_here={}, another={}}}

local filter = tm:filter{"search", "ska"}

--print(filter:sql(tm.kinds.trytest))

print "-----"
local fun = filter:search_fun("trytest")

print(filter:search_sql("trytest"))

print(fun())

local function tags(el)
   local list = {}
   for k,v in pairs(el.tags or {}) do table.insert(list, v.key) end
   return table.concat(list, ";")
end

local function sr(list)
   print("N", #list)
   for _, el in ipairs(list) do
      print(el.first, el.first, el.second, tags(el))  -- Note: tags not in object..
   end
end

sr(filter:accessible_search("trytest"))

--print("--*--")
--for _,el in pairs(tm.db:exec("SELECT * FROM tm_trytest_tags")) do
--   local list = {}
--   for k,v in pairs(el) do table.insert(list, k .. ":" .. v) end
--   print(table.concat(list, ", "))
--end
