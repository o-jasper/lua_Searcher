local maclike = require "Searcher.util.maclike"

return function(dom, name)
   return function (state, filters, expr)
      local args = {}
      for i = 2, #expr do
         local got = maclike(state, filters, expr[i])
         if got == dom then return dom end
         table.insert(args, got)
      end
      return table.concat(args, " " .. (name or expr[1]) .. " ")
   end
end
