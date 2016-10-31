--  Copyright (C) 30-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local This = require("Searcher.util.Class"):class_derive{ __constant=true }

function This:add_kind(kind)
   for _,db in ipairs(self) do db:add_kind(kind) end
end

local function do_foreach_db(...)
   for _,k in ipairs{...} do
      This[k] = function(self, ...)
         for _,db in ipairs(self) do db[k](db, ...) end
      end
   end
end
do_foreach_db("add_kind", "insert")

local Filter = require("Searcher.util.Class"):class_derive{ __constant=true }

function Filter:search(...)
   local list = {}
   for i,f in ipairs(self) do
      for _, el in pairs(f:search(...)) do
         el.i = i
         table.insert(list, el)
      end
   end
   return list
end
function Filter:search_fun(kind_name)
   return function(...) return self:search(kind_name, ...) end
end

function Filter:search_sql(...) return "Not supported" end

function This:filter(...)
   local filters = {}
   for _,db in ipairs(self) do table.insert(filters, db:filter(...)) end
   return Filter:new(filters)
end

return This
