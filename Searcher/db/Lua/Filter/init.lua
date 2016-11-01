--  Copyright (C) 30-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Filter and conversion to lua that can handle the lua-table representation
-- of messages.

local This = require("Searcher.db.raw.BaseFilter"):class_derive(
   require("Searcher.db.Lua.Filter.Base"),
   { __name="Filter" })

local function iterate_fun(self, kind_name, fun)
   local kind, entries = self.kinds[kind_name], self.entries[kind_name]
   if kind.main_key then
      for mk, entry in pairs(entries) do
         local got = fun(entry)
         if got then return got end
      end
   else
      for entry in pairs(entries) do
         local got = fun(entry)
         if got then return got end
      end
   end
end

local ins = table.insert
local function This_search(self, kind_name, ...)
   local ret = {}  -- TODO limit count, compile the whole search?
   local filter_fun = self:fun(self.kinds[kind_name])
   local pass = {...}
   iterate_fun(self, kind_name,
               function(entry)
                  if filter_fun(entry, unpack(pass)) then ins(ret, entry) end
   end)
   local order_by = self:figure_order_by()
   table.sort(ret, function(a,b) return a[order_by] < b[order_by] end)
   return ret
end

-- Note: here, no distinction between raw and not.
This.search = This_search
This.raw_search = This_search

function This:search_fun(kind_name)
   return function(...) return This_search(self, kind_name, ...) end
end
This.raw_search_fun = This.search_fun

function This:delete(kind_name, ...)
   local kind = assert(self.kinds[kind_name])
   local filter_fun = self:fun(kind)
   local mk, entries = kind.main_key, self.entries[kind_name]
   iterate_fun(self, kind_name,
               function(entry)
                  entries[mk or entry] = nil
               end)
end

function This:delete_fun(kind_name)
   return function(...) self:delete(kind_name, ...) end
end

return This
