local function w_magnitude_interpret(text)
   local value, name = string.match(text, "^([%d]+)[ ]*([numkMGT]*)$")
   if value and name then
      local factor = ({p=1e-12, n=1e-9, u=1e-6, m=1e-3, 
                       k=1e3, M=1e6, G=1e9, T=1e12})[name] or 1
      return tonumber(value)*factor
   end
end

return w_magnitude_interpret
