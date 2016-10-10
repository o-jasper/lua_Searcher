--  Copyright (C) 20-04-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local Kind = require "Searcher.Kind"
local This = Kind:class_derive{ __name="KindSql" }

-- NOTE/TODO attached to the Db...
This.sql_prep = "tm_"

function This:init()
   Kind.init(self)  -- Fills `.keyed`

   assert(self.db)
   self.sql_name = self.sql_prep .. self.name

   local cmd_strs = self.db.cmd_strs
   cmd_strs[self.name .. "_rm_id"] =
      "DELETE FROM " .. self.sql_name .. " WHERE id == ?"

   local vars = {}
   for _, var in ipairs(self.keyed) do
      table.insert(vars, var .. " == ?")
   end
   cmd_strs[self.name .. "_rm_keyed"] =
      "DELETE FROM " .. self.sql_name .. " WHERE " .. table.concat(vars, " AND ")
end

function This:rm_id(id)
   self.db:cmd(self.name .. "_rm_id")(id)
end

function This:ins_n_cmd(n)
   local cmd_name = string.format("%s_ins_%d", self.name, n)
   if not self.db.cmd_strs[cmd_name] then
      self.db.cmd_strs[cmd_name] =
         "INSERT INTO " .. self.sql_name ..
         " VALUES (" .. string.rep("?,", n) .. "?);"
   end
   return self.db:cmd(cmd_name)
end

local types = {string = "STRING", number="NUMERIC", boolean="BOOL", integer="INTEGER",
               set = "ignore", id = "INTEGER PRIMARY KEY",
}

function This:create_table_sql()
   self.args, self.sets = {}, {}

   local ret = { "id INTEGER PRIMARY KEY" }
   for _, el in ipairs(self) do --
      local name, sql_tp, p1 = el[1], types[el[2]], el[3]
      assert(name)
      self.args[name] = el
      if el[2] == "ref" then  -- Reference to something.
         table.insert(ret, name .. " INTEGER")
         self.sets[name] = p1  -- What other kind it refers to.
      elseif sql_tp and sql_tp ~= "ignore" then
         table.insert(ret, name .. " " .. sql_tp)
      end
   end
   return "CREATE TABLE IF NOT EXISTS " .. self.sql_name .. " (\n" ..
      table.concat(ret, ",\n") .. ");"
end

function This:create_table()
   self.db:exec(self:create_table_sql())
end

-- Remove if keys match exactly.
function This:rm_keyed(conflicting_this)
   local keyed = self.keyed
   if false and #keyed > 0 then
      local vals = {}
      for _, var in ipairs(keyed) do
         table.insert(vals, conflicting_this[var])
      end
      self.db:cmd(self.name .. "_rm_keyed")(unpack(vals, 1, #keyed))
   end
end
 
return This
