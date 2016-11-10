local Sql = require "Searcher.Sql"

local cmds = {
   create = [[
CREATE TABLE IF NOT EXISTS list (
   x INTEGER NOT NULL
);]],
   listall = "SELECT * FROM {%main}",
   listall_sort = [[SELECT * FROM {%main}
ORDER BY x;]],
   listrange = "SELECT * FROM {%main} WHERE x > ? AND x < ?;",
   add = "INSERT INTO {%main} VALUES (?);",
}

local repl = {main = "list"}
local s = Sql:new{filename = ":memory:", cmd_strs=cmds, repl=repl}

s.cmds.create()

local list = {}
while #list < 100 do
   local add = math.random(1000)
   table.insert(list, add)
   s.cmds.add(add)
end
table.sort(list)

local which = (arg[1] == "cmd")
if arg[1] ~= "exec" then which = math.random() < 0.5 end

for _ = 1,10 do
   local sql_list = which and s.cmds.listall_sort() or s:exec_expand(cmds.listall_sort)
   assert(#list == #sql_list)
   for i, el in ipairs(list) do
      local val = sql_list[i]
      assert(val.x == el, string.format("%s ~= %s (%d)", val.x, el, i))
   end
end
