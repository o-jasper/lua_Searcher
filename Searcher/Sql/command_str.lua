local function sql_command_str(sql_pattern, input, prep_string)
   local i = 0
   local function ret_one()
      i = i + 1
      local r = input[i]
      if r == false then
         return false
      else
         return (type(r) == "string" and [[']] .. prep_string(r) .. [[']]) or r or "NULL"
      end
   end
   return string.gsub(sql_pattern, "[?]", ret_one)
end

return sql_command_str
