--  Copyright (C) 25-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local This = require("Searcher.util.Class"):class_derive{ __constant=true }
This.Db = require "Searcher.Sql"

This.sql_prep = "tm_"

function This:init()
   self.db = self.db or self.Db:new{filename=self.filename or ":memory:",
                                    cmd_strs=cmd_strs}
   self.kinds = {}
end

local kind_code = require "Searcher.db.Sql.raw.kind_code"

function This:add_kind(kind)
   assert(type(kind) == "table")
   self.kinds[kind.name] = kind_code.prep(self.db, kind, self.sql_prep)
   assert(kind._sql_name)

   -- TODO want this text somehow available?
   self.db:exec(kind_code.create_table_sql(kind))
end

local function figure_id(self)  -- Figures out a unique id.
   local tf = 1000000
   local id = tf*(os.time() % tf) + math.floor(1000000*os.clock())
   if self.last_id >= id then id = self.last_id + 1 end
   self.last_id = id
   return id
end

This.last_id = 0

local tps = { set="table", }

-- Insert a value.
function This:insert(ins_value, new_keys)
   assert(type(ins_value) == "table")
   assert(type(ins_value.kind) == "string")
   local kind_name = ins_value.kind
   local kind = self.kinds[kind_name]

   local id = ins_value.id
   if id then  -- If with `id`, delete the old one first.
      self:rm_id(kind_name, id)
   else
      id = figure_id(self)
      ins_value.id = id
   end

   assert(kind, "Must add the kind first. Don't know: "  .. ins_value.kind)
   -- "Keying" entries only have one per those values of keys.
   -- So delete those with the same ones as now.
   if not new_keys then
      kind_code.rm_keyed(self.db, kind, ins_value)
   end

   local ignore_tp = {["return"]=true, ignore=true}
   -- Figure out the values in-order, fix references.
   local n, values = 0, {}
   for i, el in ipairs(kind) do
      local val = ins_value[el[1]]
      if val ~= nil then
         if el[2] == "ref" then  -- Insert sub-table as appropriate kind.
            if type(val) ~= "table" then
               assert(type(val) == "number" and val%1 == 0)
            else -- If not already a table reference, insert.
               val.kind = el[3]
               val = val.id or self:insert(val)
            end
         elseif ({ integer=true, time=true })[el[2]] then
            assert(type(val) == "number" and val%1 == 0,
                   string.format("Type mismatch expected integer, have %s", val))
         elseif el[2] == "set" then
            local var_name, _, kind_name = unpack(el)
            for k,v in pairs(val) do
               assert(type(v) == "table", k .. ": " .. type(v))
               v.kind = kind_name
               v[el.from_id_name or "from_id"] = id
               v[el.key_name or "key"] = k
               self:insert(v)
            end
         elseif not ignore_tp[el[2]] then
            assert(type(val) == (tps[el[2]] or el[2]),
                   string.format("Type mismatch type(%s) ~= %q",
                                 val, el[2]))
         end  -- nil.
      end
      if not (({set=true})[el[2]] or ignore_tp[el[2]]) then
         n = n + 1
         table.insert(values, val)
      end
   end
   -- Produce the insert command if needed.
   kind_code.ins_n_cmd(self.db, kind, n)(id, unpack(values, 1, n))
   return id
end

-- NOTE: doesn't delete everything related. (no garbage collection)
function This:rm_id(kind_name, id)
   self.db.cmds[kind_name .. "_rm_id"](id)
end

This.Filter = require "Searcher.db.Sql.Filter"
-- Produce a filter, which can subsequently do stuff.
function This:filter(filter, ...)
   local new = {}
   for k,v in pairs(filter) do new[k] = v end
   new.db, new.kinds = self.db, self.kinds
   return self.Filter:new(new, ...)
end

return This
