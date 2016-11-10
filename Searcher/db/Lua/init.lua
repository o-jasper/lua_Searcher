--  Copyright (C) 30-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local This = require("Searcher.util.Class"):class_derive{
   __constant=true, __name="Lua filter" }

This.last_id = 0

function This:init()
   self.entries = self.entries or {}
   self.kinds = self.kinds or {}
end

local KindMeta = require "Searcher.raw.KindMeta"

This.Filter = require "Searcher.db.Lua.Filter"

function This:add_kind(kind)
   assert(type(kind) == "table" and not self.kinds[kind.name])
   self.kinds[kind.name] = setmetatable(kind, KindMeta)
   self.entries[kind.name] = {}
end


local function rm_keyed(self, value, kind)
   local entries, mk = self.entries[kind.name], kind.main_key
   if mk then
      entries[mk] = nil
   end
   if #kind.keyed > 1 then  -- Delete everything with matching keys.
      for main_key, entry in pairs(entries) do
         for _,key in ipairs(kind.keyed) do
            if entry[key] == value[key] then entries[main_key] = nil end
         end
      end
   end
end

function This:insert(ins_value, new_keys)
   local kind_name = ins_value.kind
   local kind = self.kinds[kind_name]
   if not new_keys and #kind.keyed ~= 1 then -- Delete older ones.
      rm_keyed(self, ins_value, kind)
   end

   -- Add principal entry.
   local mk = kind.main_key
   if mk then  -- Tabled by main key.  -- NOTE values not really checked.
      self.entries[kind_name][ins_value[mk]] = ins_value
   else  -- Tabled by whole thing.
      self.entries[kind_name][ins_value] = true
   end

   -- Add referenced entries.
   for name, skind_name in pairs(kind.sets) do
      for key, value in pairs(ins_value[key] or {}) do
         value.key = key

         value.kind = value.kind or skind_name
         assert(value.kind == skind_name, "Kinds not as required")
         value.from = ins_value
         self:insert(value)
      end
   end
end

function This:filter(filter, ...)
   filter.db = self
   filter.kinds = self.kinds
   filter.entries = self.entries
   return self.Filter:new(filter)
end

return This
