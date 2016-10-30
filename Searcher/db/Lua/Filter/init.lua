--  Copyright (C) 30-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Filter and conversion to lua that can handle the lua-table representation
-- of messages.

local This = require("Searcher.db.Lua.Filter.Base"):class_derive{ __name="Filter" }
local ins = table.insert

local function This_search_fun(self, kind_name)
   local kind, entries = self.kinds[kind_name], self.entries[kind_name]
   local filter_fun, ret = self:fun(self, kind), {}
   if kind.main_key then
      return function()
         for mk, entry in pairs(entry) do
            if filter_fun(entry) then ins(ret, entry) end
         end
         return ret
      end
   else
      return function()
         for entry in pairs(entries) do
            if filter_fun(entry) then ins(ret, entry) end
         end
         return ret
      end
   end
end
This.search_fun = This_search_fun
-- TODO/NOTE hrmm the distinction between accessible and inaccessible is gone here..
-- need to establish the non-accessible as non-oparational from the get-go.
--
-- TODO also, tags are no longer separate objects.
function This:accessible_search(kind_name, ...)
   return This_search_fun(self, kind_name)(...)
end
This.search = This.accessible_search

return This
