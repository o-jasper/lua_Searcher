
local maclike = require "Searcher.util.maclike"
local dom_bin_fun = require "Searcher.db.raw.dom_bin_fun"

local Add = {
   ["."] = function(state, filters, expr)
      if #expr == 2 then
         return "d" .. state.depth .. "_" .. expr[2]
      else
         assert(#expr == 3 and type(expr[3]) == "string")
         return  maclike(state, filters, expr[2]).. "." .. expr[3]
      end
   end,
   ["not"] = function(state, filters, expr)
      assert(#expr == 2)
      local got = maclike(state, filters, expr[2])
      
      return got == "true" and "false" or got == "false" and "true" or
         "(not " .. got .. ")"
   end,

   ["and"] = dom_bin_fun("false"), ["or"] = dom_bin_fun("true"),

   ["kind=="] = function(state, filters, expr)
      assert(#expr == 2)
      if state.kind == "any" then
         return "(d" .. state.depth .. ".kind" .. " == \"" .. expr[2] .. "\")"
      elseif state.kind_name == expr[2] then
--         assert(state.kind_name == expr.kind, -- ???
--                string.format("kind name mismatch? %s %s", state.kind_name, expr.kind))
         return "true"
      else
         return "false"
      end
   end,

   like = function(state, filters, expr)
      return "string.find(" .. maclike(state, filters, expr[2]) .. ", \"^" ..
         string.gsub(string.gsub(expr[3], "%%", ".*"), "_", ".") .. "$\")"
   end,

   funwrap = function(state, filters, expr)
      return "(function()\n" .. maclike(state, filters,expr[2]) .. "\nend)()\n"
   end,

   into_topname = function(state, filters, expr)
      local topname, kindname, sub_expr = unpack(expr, 2)
      local new_kind = state.kinds[kindname]
      assert(new_kind, "Could not find kind: " .. kindname)

      local args, input, depth = {}, {}, state.depth + 1
      for _, el in ipairs(new_kind) do
         table.insert(args,  "d" .. depth .. "_" .. el[1])
         table.insert(input, topname .. "." .. el[1])
      end

      local new_state = {
         depth = depth, kind = new_kind, kind_name = new_kind.name,
         kinds = state.kinds,
      }
      local m = maclike(new_state, filters, sub_expr)
      if #args > 0 then
         return ("local " .. table.concat(args, ", ") .. " = " ..
                    table.concat(input, ", ") .. "\nreturn " ..
                    m)
      else
         return "return " .. m
      end
   end,

   into_ref = function(state, filters, expr)
      local elname, kindname, sub_expr = unpack(expr, 2)
      for _, el in ipairs(state.kind) do  -- Figure which, and produce new args.
         if el[1] == elname then
            assert(el[2] == "table")
            return {"funwrap", {"into_topname",
                                "d" .. state.depth .. "_" .. elname, kindname, sub_expr}}
         end
      end
      error()
   end,

   into_set = function(state, filters, expr)
      local elname, kindname, sub_expr = unpack(expr, 2)
      local m = maclike(state, filters,
                        {"into_topname", "el", kindname, sub_expr})
      local list = maclike(state, filters, {".", elname})
      return [[(function()
  local function one(el)
    ]] .. m .. "\n  end\n  for _, el in ipairs(" .. list .. [[) do
    if one(el) then return true end
end end)()]]
   end,
}

local Public = {}
for k,v in pairs(require "Searcher.db.raw.base_filter") do Public[k] = v end
for k,v in pairs(Add) do Public[k] = v end

return Public
