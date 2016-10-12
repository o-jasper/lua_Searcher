local Filter = require "Searcher.filter.Lua"

local kinds = {
   trytest = {
      name = "trytest",
      { "first",  "number" },
      { "second", "string", searchable=true },
      { "tags",   "set", "trytest_tags", searchable=true },
   },
   trytest_tags = {
      name = "trytest_tags",
      -- TODO this does not allow for arbitrary graphs. Kinds can only go down tree-style.
      --  Perhaps the specification approach should reflect that.
      {"from_id", "ref", "trytest", keyed=true},
      {"key", "string", keyed=true, searchable=true}
   }
}

local list = {
   {kind="trytest", first=1, second="second two", tags={}},
   {kind="trytest", first=1, second="two", tags={has_a_tag={}, another={}}},
   {kind="trytest", first=1, second="two sec", tags={has_a_tag={}, another={}}},
   {kind="trytest", first=1, second="not here", tags={sec_but_here={}, another={}}},
}

local args= {"search", "sec", memoize={}, kinds=kinds}
local filter = Filter:new(args)

for i, el in ipairs(list) do
   local tags = {}
   for k,v in pairs(el.tags) do
      table.insert(tags, { key = k })
   end
   local ret = filter:apply(kinds.trytest,
                            { tags = tags, kind=el.kind, first=el.first, second=el.second})
   if ret then
      print("**", i)
      for k,v in pairs(el) do
         print("f", k,v)
      end      
   end
end
