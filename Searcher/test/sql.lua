local Sql = require "Searcher.Sql"

local cmds = {
   create = [[
CREATE TABLE IF NOT EXISTS list (
   x INTEGER NOT NULL,
   y INTEGER
);]],
   listall = "SELECT * FROM {%main}",
   listall_sort = [[SELECT * FROM {%main}
ORDER BY x;]],
   listrange = "SELECT * FROM {%main} WHERE x > ? AND x < ?;",
   add = "INSERT INTO {%main} VALUES (?, ?);",
}

local repl = {main = "list"}
local s = Sql:new{filename = ":memory:", cmd_strs=cmds, repl=repl}

s.cmds.create()

local list = {}
while #list < 100 do
   local add,addy = math.random(1000), math.random(1000)
   table.insert(list, add)
   s.cmds.add(add, addy)
end
table.sort(list)

local which = (arg[1] == "cmd")
if arg[1] == "random" then which = (math.random() < 0.5) end

for k = 1,10 do
   print("DO", k)
   local sql_list = which and s.cmds.listall_sort() or s:exec_expand(cmds.listall_sort)
   assert(#list == #sql_list)
   for i, el in ipairs(list) do
      local val = sql_list[i]
      assert(val and val.x == el, string.format("%s ~= %s (%d)", val and val.x, el, i))
   end
end
