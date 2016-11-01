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

-- TODO feh this thing keeps reoccuring..
local function tree_inequal(a, b, say)
   if type(a) ~= type(b) then
      return true, say .. " type inequal; " .. type(a) .. " ~= " .. type(b)
   elseif type(a) == "table" then
      for k, v in pairs(a) do
         local ne,s = tree_inequal(v, b[k], say .. "/" .. k)
         if ne then return ne,s end
      end
   else
      return a ~= b, say .. " value inequal"
   end
end

local Filter = require("Searcher.util.Class"):class_derive{ __constant=true }
function Filter:search(...)
   local lists = {}
   for i,f in ipairs(self) do
      print(f.__name)
      table.insert(lists, 1, {})
      for _, el in pairs(f:search(...)) do
         table.insert(lists[1], el)
      end
   end
   for i = 2, #lists do
      assert( #(lists[1]) == #(lists[i]) )
      local ne, s = tree_inequal(lists[1], lists[i], "inequal: ")
      assert(not ne, s)
   end
   return lists[1]
end
function Filter:search_fun(kind_name)
   return function(...) return self:search(kind_name, ...) end
end

function Filter:search_sql(...) return "SQL printing not supported" end

function This:filter(...)
   local filters = {}
   for _,db in ipairs(self) do table.insert(filters, db:filter(...)) end
   return Filter:new(filters)
end

return This
