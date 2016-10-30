--  Copyright (C) 20-04-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Filter and conversion to lua that can handle the lua-table representation
-- of messages.

local This = require("Searcher.util.Class"):class_derive{ __name="Filter" }

function This:init()
   self.memoize = {}
end
 
local maclike = require "Searcher.util.maclike"
local lua_filters = require "Searcher.db.Lua.Filter.raw.lua"

function This:lua(kind)
   assert(self.kinds)
   local lua = maclike(
      {depth=0, kind=kind, kind_name=kind.name, kinds=self.kinds},
      lua_filters,
      {"into_topname", "d0", kind.name, self})
   return "return function(d0)\n" .. lua .. "\nend"
end

local function this_fun(self, kind)
   local fun = self.memoize[kind.name]
   if not fun then
      fun = loadstring(self:lua(kind))()
      self.memoize[kind.name] = fun
   end
   return fun
end

This.fun = this_fun

function This:apply(kind, msg)
   local kind = kind or self.kinds[msg.kind]
   assert(kind, string.format("Could not find kind: %s", msg.kind))
   return this_fun(self, kind)(msg)
end

return This
