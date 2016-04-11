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
   rawset(kind, "args", {})
   rawset(kind, "ref", {})

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
   return "CREATE TABLE IF NOT EXISTS " .. kind.sql_name .. " (\n" ..
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
local function rm_keyed(self, kind, keyed, ins_value)
   if #keyed > 0 then
      local vals = {}
      for _, var in ipairs(keyed) do
         table.insert(vals, ins_value[var])
      end
      kind.sql_rm_keyed(unpack(vals, 1, #keyed))
   end   
end

-- Insert a value.
function This:insert(ins_value, brand_new)
   assert(type(ins_value) == "table")
   assert(type(ins_value.kind) == "string")
   local kind = self.kinds[ins_value.kind]

   local id = ins_value.id
   if id then
      kind.sql_rm_id(id)
   else
      id = figure_id(self)
      ins_value.id = id
   end

   assert(kind, "Must add the kind first. Don't know: "  .. ins_value.kind)
   -- "Keying" entries only have one per those values of keys.
   -- So delete those with the same ones as now.
   rm_keyed(self, kind, not brand_new and kind.keyed, ins_value)

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

   -- Figure out things that refer to self.
   for _, el in ipairs(kind.ref_self or {}) do
      local var_name, refself_kind_name, from_id_name = unpack(el)
      ins_value[var_name][from_id_name or "from_id"] = id
      ins_value[var_name].kind = refself_kind_name
      self:insert(ins_value[var_name])
   end
   -- Things that refer to self via a key
   for _, el in ipairs(kind.key_self or {}) do
      local var_name, keyself_kind_name, from_id_name, key_name = unpack(el)
      for k,v in pairs(ins_value[var_name] or {}) do
         v.kind = keyself_kind_name
         v[from_id_name or "from_id"] = id
         v[key_name or "key"] = k
         self:insert(v)
      end
   end

   -- Produce the insert command if needed.
   kind.sql_insert_n[n](id, unpack(values, 1, n))
   return id
end

function This:kind_metatable()
   return {  -- Some things are added as you go.
      __index = function(kind, key)
         if key == "sql_name" then
            rawset(kind, "sql_name", self.prep .. kind.name)
         elseif key == "sql_var" then
            return "el"
         elseif key == "sql_insert_n" then
            local ret = setmetatable({},  -- Compiles insert-this-number on fly.
               { __index = function(list, n)
                    local sql = "INSERT INTO " .. kind.sql_name ..
                       " VALUES (" .. string.rep("?,", n) .. "?);"
                    rawset(list, n, self.db:compile(sql))
                    return list[n]
            end})
            rawset(kind, "sql_insert_n", ret)
         elseif key == "sql_rm_id" then
            rawset(kind, rm_id, self.db:compile("DELETE FROM " .. kind.sql_name ..
                                                   " WHERE id == ?"))
         elseif key == "sql_rm_keyed" then
            local vars = {}
            for _, var in ipairs(kind.keyed) do
               table.insert(vars, var .. " == ?")
            end
            local sql = "DELETE FROM " .. kind.sql_name ..
               " WHERE " .. table.concat(vars, " AND ")
            rawset(kind, "sql_rm_keyed", self.db:compile(sql))
         elseif key == "self" then
            rawset(kind, "self", self)
         elseif key == "pref_order_by" then
            for _, el in ipairs(kind) do
               if el.order_by_this then
                  rawset(kind, "pref_order_by", el[1])
                  return el[1]
               end
            end
         elseif key == "keyed" then
            local keyed = {}
            for _, el in ipairs(kind) do
               if el.keyed then
                  table.insert(keyed, el[1])
               end
            end
            rawset(kind, "keyed", keyed)
         end
         return rawget(kind, key)
      end,
      __newindex = function() error("Hands off") end,
   }
end

function This:add_kind(kind)
   local kind_name = kind.name
   kind = setmetatable(kind, self:kind_metatable())
   self.kinds[kind_name] = kind
   self.db:exec(self:insert_sql_create_table(kind))
end

local filter_sql = require("Searcher.TableMake.filter").filter_sql

function This:filter_sql(filter)
   local kind = self.kinds[filter.in_kind]
   local sql = "SELECT * FROM " .. kind.sql_name .. " " .. kind.sql_var .. "\n WHERE"
   sql = sql .. filter_sql(kind, filter)
   local order_by = filter.order_by or kind.pref_order_by
   if order_by then
      sql = sql .. "\nORDER BY " .. order_by .. (filter.desc and " DESC" or "")
   end
   return sql
end

function This:filter(filter) return self.db:exec(self:filter_sql(filter)) end

function This:delete_by_filter_sql(filter)
   local kind = self.kinds[filter.in_kind]
   local sql = "DELETE FROM " .. kind.sql_name "\n WHERE"
   return sql .. filter_sql(kind, filter)
end
function This:delete_by_filter(filter)
   return self.db:exec(self:delete_by_filter_sql(filter))
end

return This
