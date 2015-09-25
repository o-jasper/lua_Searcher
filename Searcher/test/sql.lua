local Sql = require "Searcher.Sql"

local cmds = {
   create = [[
CREATE TABLE IF NOT EXISTS list (
   x INTEGER NOT NULL
);]],
   listall = "SELECT * FROM {%main}",
   listall_sort = [[SELECT * FROM {%main}
ORDER BY x]],
   listrange = "SELECT * FROM {%main} WHERE x > ? AND x < ?",
   add = "INSERT INTO {%main} VALUES (?)",
}

local repl = {main = "list"}
local s = Sql:new{filename = ":memory:", cmd_strs=cmds, repl=repl}

s.cmds.create()

local list, i = {}, 0
while i < 100 do
   local add = math.random(1000)
   table.insert(list, add)
   s.cmds.add(add)
   i = i + 1
end

table.sort(list)
local sql_list = s.cmds.listall_sort()
for i, el in ipairs(list) do
   local val = sql_list[i]
   assert(val.x == el, string.format("%s ~= %s", val.x, el))
end
