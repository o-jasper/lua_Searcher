local time_interpret = require "Searcher.fromtext.time.interpret"
local w_magniture_interpret = require "Searcher.fromtext.w_magnitude_interpret"

return function(values, mf, matchable)
   local function add(key, fun)
      table.insert(matchable, key)
      mf[key] = fun
   end
   local function inv(m) return string.find(m, "^%-") end

   for _, name in pairs(values.textable or {}) do
      add("%-?" .. name .. "=", function(self, _, m, v)
         self:equal(name, v, inv(m))
      end)
      add(name .. "!=", function(self, _, m, v)
         self:equal(name, v, true)
      end)
      add("%-?" .. name .. "like:", function(self, _, m, v)
         self:like(name, v, inv(m))
      end)
      add("%-?" .. name .. ":", function(self, _, m, v)
         self:like(name, "%" .. v .. "%", inv(m))
      end)
   end

   for _, name in pairs(values.comparable or {}) do
      add(name .. "lt:", function(self, _, m, v)
         self:lt(name, w_magnitude_interpret(v))
      end)
      add(name .. "gt:", function(self, _, m, v)
         self:gt(name, w_magnitude_interpret(v))
      end)
      add(name .. "!?=", function(self, _, m, v)
         self:equal(name, v, inv(m))
      end)
   end

   for _, name in pairs(values.timable or {}) do
      add(name .. "_before:", function(self, _, m, v)
         local t = time_interpret(v)
         if t then self:lt("access", t) end
      end)
      
      add(name .. "_after:", function(self, _, m, v)
         local t = time_interpret(v)
         if t then self:gt("access", t) end
      end)
   end
end
