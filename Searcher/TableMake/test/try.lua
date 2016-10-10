local TableMake = require "Searcher.TableMake"

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
   {"from_id", "table", "trytest", keyed=true},
   {"key", "string", keyed=true, searchable=true}
}

tm:insert{kind="trytest", first=1, second="ska two"}
tm:insert{kind="trytest", first=1, second="two", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="two ska", tags={has_a_tag={}, another={}}}
tm:insert{kind="trytest", first=1, second="not here", tags={ska_here={}, another={}}}

local args= {"search", "ska", memoize={}, kinds=tm.kinds}
local F = require "Searcher.TableMake.Filter"
local filter = require("Searcher.TableMake.FilterBoth"):new(args)

--print(filter:sql(tm.kinds.trytest))

print "-----"
local fun = filter:fun(tm.kinds.trytest)

local function sr(list)
   print("N", #list)
   for _, el in ipairs(list) do
      el.tags = {}
      print(fun(el))
      for k,v in pairs(el) do
         print("f", k,v)
      end
   end
end

sr(filter:search(tm.kinds.trytest))
