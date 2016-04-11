--  Copyright (C) 11-04-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local This = { __constant=true }
This.__index = This

This.Db = require "Searcher.Sql"

function This:new(new)
   new = setmetatable(new or {}, self)
   new:init()
   return new
end

This.types = {string = "STRING", number="NUMERIC", boolean="BOOL", integer="INTEGER"}

This.prep = "tm_"

function This:init()
   self.db = self.db or self.Db:new{filename=self.filename or ":memory:",
                                    cmd_strs=cmd_strs}
   self.kinds = {}
end

function This:insert_sql_create_table(kind)
   kind.args, kind.ref = kind.args or {}, kind.ref or {}

   local ret = { "id INTEGER PRIMARY KEY" }
   for _, el in ipairs(kind) do --
      local name, sql_tp, p1 = el[1], self.types[el[2]]
      assert(name)
      kind.args[name] = el
      if not sql_tp then  -- Reference to something.
         assert(el[2] == "ref")
         table.insert(ret, name .. " INTEGER")
         kind.ref[name] = p1  -- What other kind it refers to.
      else
         table.insert(ret, name .. " " .. sql_tp)
      end
   end
   return "CREATE TABLE IF NOT EXISTS " .. self.prep .. kind.name .. "(\n" ..
      table.concat(ret, ",\n") .. ");"
end

local function figure_id(self)
   local tf = 1000000
   local id = tf*(os.time() % tf) + math.floor(1000000*os.clock())
   if self.last_id >= id then id = self.last_id + 1 end
   self.last_id = id
   return id
end

This.last_id = 0

-- Remove things with equal keys.
local function rm_keyed(self, keyed, ins_value)
   if keyed then
      if not keyed.compiled then
         local vars = {}
         for _, var in ipairs(keyed) do
            table.insert(vars, var .. " == ?")
         end
         local sql = "DELETE FROM " .. prep .. kind_name ..
            " WHERE " .. table.concat(vars, " AND ")
         keyed.compiled = self.db:compile(sql)
      end
      local vals = {}
      for _, var in ipairs(keyed) do
         table.insert(vals, ins_value[var])
      end
      keyed.compiled(unpack(vals, 1, #keyed))
   end   
end

-- Insert a value.
function This:insert(ins_value)
   assert(type(ins_value) == "table")
   assert(type(ins_value.kind) == "string")
   local kind = self.kinds[ins_value.kind]
   assert(kind, "Must add the kind first. Don't know: "  .. ins_value.kind)
   -- "Keying" entries only have one per those values of keys.
   -- So delete those with the same ones as now.
   rm_keyed(self, kind.keyed)

   -- Figure out the values in-order, fix references.
   local n, values = 0, {}
   for i, el in ipairs(kind) do
      local val = ins_value[el[1]]
      if val ~= nil then
         n = i
         if el[2] == "ref" then  -- Insert sub-table as appropriate kind.
            if type(val) ~= "table" then
               assert(type(val) == "number" and val%1 == 0)
            else -- If not already a table reference, insert.
               val.kind = el[3]
               val = val.id or self:insert(val)
            end
         else  -- Insert value.
            assert(type(val) == el[2], string.format("Type mismatch %s ~= %s",
                                                     type(val), el[2]))
         end  -- nil.
      end
      table.insert(values, val)
   end
   local id = figure_id(self)

   -- Figure out things that refer to self.
   for _, el in ipairs(kind.ref_self or {}) do
      local var_name, refself_kind_name, from_id_name = unpack(el)
      ins_value[var_name][from_id_name or "from_id"] = id
      ins_value[var_name].kind = refself_kind_name
      self:insert(ins_value[var_name])
   end
   -- Things that refer to self via a key
   for _, el in ipairs(kind.key_self or {}) do
      local var_name, keyself_kind_name, key_name, from_id_name = unpack(el)
      for k,v in pairs(ins_value[var_name] or {}) do
         v.kind = keyself_kind_name
         v[from_id_name or "from_id"] = id
         v[key_name or "key"] = k
         self:insert(v)
      end
   end

   -- Produce the insert command if needed.
   kind.insert_cmd = kind.insert_cmd or {}
   if not kind.insert_cmd[n] then
      local sql = "INSERT INTO " .. self.prep .. ins_value.kind ..
         " VALUES (" .. string.rep("?,", n) .. "?);"
      kind.insert_cmd[n] = self.db:compile(sql)
   end
   -- Run insert command, return the `id`
   kind.insert_cmd[n](id, unpack(values, 1, n))
   return id
end

-- function This:extend_kind   -- TODO

function This:add_kind(kind)
   local kind_name = kind.name
   self.kinds[kind_name] = kind
   print(self:insert_sql_create_table(kind))
   self.db:exec(self:insert_sql_create_table(kind))
end



return This
