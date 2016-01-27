--  Copyright (C) 07-01-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Helps out putting formulator and database together.

local This = {}
This.__index = This

function This:new(new)
   new = setmetatable(new, self)
   new:init()
   return new
end

function This:init()
   assert(self.Formulator)
   --assert(self.db)
end

This.allow_direct = { 
   like = 2, not_like = 2, text_like = 2, text_sw = 2,
   equal = 2, lt = 2, gt = 2, after = 2, before = 2,
   auto_by = 0,
   limit = 2,
}
This.search_term = ""

function This:form(search_term, state)
   local search_term, state = search_term or self.search_term, state or {}
   assert(type(search_term == "string"))

   local form = self.Formulator:new()
   form:search_str(search_term)

   -- Do the search terms the state wants to add.
   for method, args in pairs(state.direct or {}) do
      local allow = self.allow_direct[method or "dont"]
      if allow and type(method == "string") and type(args) == "table" then
         while #args > allow do table.remove(args) end  -- Enforce maximum.
         form[method](form, unpack(args))
      end
   end

   return form
end

This.limit = { 1, 50 }

function This:produce(search_term, state, limit)
   assert(self.db)
   local form, list = self:form(search_term, state), nil
   form:limit(unpack(limit or self.limit))
   pcall(function()
         list = self.db:exec(form:sql_pattern(), unpack(form:sql_values()))
   end)

   return list or {{"FAIL"}}, form
end

return This
