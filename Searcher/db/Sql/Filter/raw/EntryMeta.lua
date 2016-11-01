--  Copyright (C) 26-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Data-like object that looks into Sql for values.

local EntryMeta = {}

local function new_1(filter, kind_name, new)
   local kind, by_id =
      assert(filter.kinds[kind_name], "Couldn't figure kind: " .. kind_name), {}
   for key,arg in pairs(kind.args) do
      if arg[2] == "ref" then  -- These need to be computed later.
         by_id[key] = new[key]
         new[key] = nil
      end
   end
   new._kind, new._by_id = kind, by_id
   new._filter = filter
   return setmetatable(new, EntryMeta)
end

-- TODO note the `tm_` but that is changable elsewhere.
function EntryMeta.__index(self, key)
   local filter, kind = rawget(self, "_filter"), rawget(self, "_kind")

   local arg = kind.args[key]
   if not arg then return end

   if arg[2] == "set" then  -- A set of things.
      -- TODO add `.cmds` for it.
      local str = string.format("SELECT * FROM tm_%s\nWHERE from_id == ? ;", arg[3])
      local list = {} -- Do query, make accessible
      for _, el in ipairs(filter.db:exec(str, rawget(self, "id"))) do
         table.insert(list, new_1(filter, arg[3], el))
      end
      self[key] = list  -- Memoize and return.
      return list
   end
      
   local by_id = self._by_id[key]  -- Reference into sub-kind, grab it.
   if arg[2] == "ref" and by_id then
      local list = filter.db.cmds[kind._sql_name .. "_get_id"](self._by_id[key])

      assert( #list <=2 )  -- Multiple? Must be bug.

      if #list == 1 then  -- Found it, make accessible, use it.
         self[key] = new_1(filter, arg[3], list[1])
         return self[key]
      else  -- No cigar, store it as missing.
         local missing = self._by_id._missing or {}
         self._by_id._missing = missing
         missing[key] = by_id
         self._by_id[key] = nil
         return
      end
   end
end

EntryMeta.new_1 = new_1
return EntryMeta
