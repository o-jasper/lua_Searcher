
local string_split = require "Searcher.util.string_split"

-- Splits things up by whitespace and quotes.
local function _portions(str)
   local list = {}
   for i, el in pairs(string_split(str, "\"")) do
      if i%2 == 1 then
         for _, sel in pairs(string_split(el, " ")) do table.insert(list, sel) end
      else
         table.insert(list, el)
      end
   end
   return list
end

local function parsed_list(matchable, search_string)
   local ret, dibs = {}, false
   for _, el in pairs(_portions(search_string)) do
      local done = false
      for _, m in pairs(matchable) do
         local _, n = string.find(el, m)
         if n then -- Match.
            if #el == n then
               dibs = m  -- All of them, keep.
               done = true
               break
            else
               table.insert(ret, {m=m, v=string.sub(el, n + 1)})
               done = true
               break
            end
         end
      end
      if not done then
         if dibs then -- Previous matched, get it.
            table.insert(ret, {m=m, v=el})
            dibs = nil
         else 
            table.insert(ret, {v=el})
         end
      end
   end
   return ret
end

return parsed_list
