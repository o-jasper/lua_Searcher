--  Copyright (C) 20-04-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- TODO the db should do this, not the Kind..?

local KindMeta = require "Searcher.raw.KindMeta"
local Public = {}

function Public.prep(db, kind, sql_prep)
   assert(kind.name)
   kind = setmetatable(kind, KindMeta)  -- Fills `.keyed`

   kind._sql_name = rawget(kind, "_sql_name") or (sql_prep .. kind.name)

   db.cmd_strs[kind.name .. "_rm_id"] =
      "DELETE FROM " .. kind._sql_name .. " WHERE id == ?"

   db.cmd_strs[kind.name .. "_get_id"] =
      "SELECT * FROM " .. kind._sql_name .. " WHERE id == ?"

   -- TODO if have references, allow said references to search for this thing.

   local vars = {}
   for _, var in ipairs(kind.keyed) do
      table.insert(vars, var .. " == ?")
   end
   db.cmd_strs[kind.name .. "_rm_keyed"] =
      "DELETE FROM " .. kind._sql_name .. " WHERE " .. table.concat(vars, " AND ")

   return kind
end

function Public.ins_n_cmd(db, kind, n)
   local cmd_name = string.format("%s_ins_%d", kind.name, n)
   if not db.cmd_strs[cmd_name] then
      db.cmd_strs[cmd_name] =
         "INSERT INTO " .. kind._sql_name ..
         " VALUES (" .. string.rep("?,", n) .. "?);"
   end
   return db.cmds[cmd_name]
end

local types = {string = "STRING", number="NUMERIC", boolean="BOOL", integer="INTEGER",
               set = "ignore", id = "INTEGER PRIMARY KEY",
}

function Public.create_table_sql(kind)
   local ret = { "id INTEGER PRIMARY KEY" }
   for _, el in ipairs(kind) do
      local name, sql_tp = el[1], types[el[2]]
      if el[2] == "ref" then  -- Reference to something.
         table.insert(ret, name .. " INTEGER")
      elseif sql_tp and sql_tp ~= "ignore" then
         table.insert(ret, name .. " " .. sql_tp)
      end
   end
   return "CREATE TABLE IF NOT EXISTS " .. kind._sql_name .. " (\n" ..
      table.concat(ret, ",\n") .. ");"
end

function Public.create_table(db, kind)
   db:exec(Public.create_table_sql(kind))
end

-- Remove if keys match exactly.
function Public.rm_keyed(db, kind, conflicting_this)
   local keyed = kind.keyed or {}
   if #keyed > 0 then
      local vals = {}
      for _, var in ipairs(keyed) do
         table.insert(vals, conflicting_this[var])
      end
      db.cmds[kind.name .. "_rm_keyed"](unpack(vals, 1, #keyed))
   end
end
 
return Public
