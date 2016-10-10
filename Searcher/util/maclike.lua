local function maclike(state, filters, expr)
   if type(expr) == "table" then
      local got = filters[expr[1]] and filters[expr[1]](state, filters, expr)
      return got and maclike(state, filters, got) or expr
   else
      return tostring(expr)
   end
end

return maclike
