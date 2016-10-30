-- Base filter set for everything.

local maclike = require "Searcher.util.maclike"

local Public = {
   ["true"] = function() return "true" end,
   ["false"] = function() return "false" end,

   str = function(state, filters, expr)
      assert(#expr == 2 and type(expr[2]) == "string")
      return "'" .. expr[2] .. "'"
   end,

   -- TODO n-out-of-m?
   search_like = function(state, filters, expr)
      local kind, ret = state.kind, {"or"}

      for _, el in ipairs(kind) do
         if el.searchable then
            local sub = {"or"}
            if el[2] == "string" then
               for i = 2,#expr do
                  table.insert(sub, {"like", {".", el[1]}, expr[i]})
               end
            elseif el[2] == "ref" then
               table.insert(sub, {"into_ref", el[1], expr})
            elseif el[2] == "set" then
               table.insert(sub, maclike(state, filters, {"into_set", el[1], el[3], expr}))
            end
            table.insert(ret, #sub > 2 and sub or sub[2])
         end
      end
      return #ret > 2 and ret or ret[2] or {"true"}
   end,

   search = function(state, filters, expr)
      local ret = {"search_like"}
      for i = 2,#expr do
         table.insert(ret, "%" .. expr[i] .. "%")
      end
      return ret
   end
}

-- Binary functions.
local function binary_fun(state, filters, expr)
   local args = {}
   for i = 2, #expr do
      table.insert(args, maclike(state, filters, expr[i]))
   end
   return table.concat(args, " " .. expr[1] .. " ")
end

for _,op in ipairs{"+", "*", "/", "-", ">", "<", ">=", "<=", "==", "=", "%"} do
   Public[op] = binary_fun
end

return Public
