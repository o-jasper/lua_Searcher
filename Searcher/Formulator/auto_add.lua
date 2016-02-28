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
         return true
      end)
      add(name .. "!=", function(self, _, m, v)
         self:equal(name, v, true)
         return true
      end)
      add("%-?" .. name .. "like:", function(self, _, m, v)
         self:like(name, v, inv(m))
         return true
      end)
      add("%-?" .. name .. ":", function(self, _, m, v)
         self:like(name, "%" .. v .. "%", inv(m))
         return true
      end)
   end

   add("like:", function(self, _, m,v)
       self:text_like(v)
       return true
   end)

   local function orfun(self, state, m,v)
      self:mode_or()

      local gotnum = tonumber(string.match(v, "[%d]+"))
      if gotnum or string.find(v, "^[%s]*$") then
         state["or"] = gotnum or 2
      else
         self.match_funs.default(self, state, m, v)
         state["or"] = 1
      end
      return true
   end
   add("or:", orfun)
   add("OR",  orfun)

   for _, name in pairs(values.comparable or {}) do
      add(name .. "lt:", function(self, _, m, v)
         self:lt(name, w_magnitude_interpret(v))
         return true
      end)
      add(name .. "gt:", function(self, _, m, v)
         self:gt(name, w_magnitude_interpret(v))
         return true
      end)
      add(name .. "!?=", function(self, _, m, v)
         self:equal(name, v, inv(m))
         return true
      end)
   end

   for _, name in pairs(values.timable or {}) do
      add(name .. "_before:", function(self, _, m, v)
         local t = time_interpret(v)
         if t then self:lt("access", t) end
         return true
      end)
      
      add(name .. "_after:", function(self, _, m, v)
         local t = time_interpret(v)
         if t then self:gt("access", t) end
         return true
      end)
   end

   for k,v in pairs(values.tags or {}) do
      add(k .. ":", function(self, _, m, v)
         self:tags(v, "bookmark_tags")
         return true
      end)
   end
   -- TODO tags.
end
