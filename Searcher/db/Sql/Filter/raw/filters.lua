
local maclike = require "Searcher.util.maclike"
local dom_bin_fun = require "Searcher.db.raw.dom_bin_fun"

local Add = {
   ["."] = function(state, filters, expr)
      if #expr ~= 2 then 
         assert(#expr == 3 and type(expr[3]) == "string")
         return  maclike(state, filters, expr[2]).. "." .. expr[3]
      elseif state.depth == 0 then
         return expr[2]
      else
         return "d" .. state.depth .. "." .. expr[2]
      end
   end,
   ["not"] = function(state, filters, expr)
      assert(#expr == 2)
      local got = maclike(state, filters, expr[2])
      
      return got == "true" and "false" or got == "false" and "true" or
         "(NOT" .. got .. ")"
   end,

   ["true"] = function(...) return "TRUE" end,
   ["false"] = function(...) return "FALSE" end,

   ["and"] = dom_bin_fun("false", "AND"), ["or"] = dom_bin_fun("true", "OR"),

   ["kind=="] = function(state, filters, expr)
      return (state.kind ~= expr[2] and state.kind ~= "any" and "false") or "true"
   end,

   like = function(state, filters, expr)
      return maclike(state, filters, expr[2]) .. " LIKE '" .. expr[3] .. "'"
   end,

-- TODO refs basically stuffed-on, i reckon.
   into_ref = function(state, filters, expr)
      error("TODO")
   end,

   into_set = function(state, filters, expr)
      local elname, kindname, sub_expr = unpack(expr, 2)
      local new_kind = state.kinds[kindname]
      local new_state = {
         depth = state.depth + 1, kind=new_kind, kind_name = new_kind.name,
         kinds=state.kinds,
      }
      -- Go through the list referring here.
      return string.format(
         "(EXISTS (SELECT * FROM tm_%s d%d\nWHERE from_id == d%d.id AND\n%s))",
         kindname, new_state.depth,
         state.depth,
         maclike(new_state, filters, sub_expr))
   end,
}

local Public = {}  -- >TODO
for k,v in pairs(require "Searcher.db.raw.base_filter") do Public[k] = v end
for k,v in pairs(Add) do Public[k] = v end

return Public
