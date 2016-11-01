 local SqlDB = require "Searcher.db.Sql"
 local LuaDB = require "Searcher.db.Lua"

local TableMake = require "Searcher.db.test.Combine"
local tm = TableMake:new{SqlDB:new{file=":memory:"}, LuaDB:new()}

tm:add_kind{
   name = "trytest",
   { "first", "number" },
   { "second", "string", searchable=true },
   {"tags", "set", "trytest_tags", "key", searchable=true}  -- TODO use the fourth argument.
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

local filter = tm:filter{"search", "ska", order_by="second"}

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
      print(el.i, el.first, el.first, el.second, tags(el))  -- Note: tags not in object..
   end
end

sr(filter:search("trytest"))

--print("--*--")
--for _,el in pairs(tm.db:exec("SELECT * FROM tm_trytest_tags")) do
--   local list = {}
--   for k,v in pairs(el) do table.insert(list, k .. ":" .. v) end
--   print(table.concat(list, ", "))
--end
