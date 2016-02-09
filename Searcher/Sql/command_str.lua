local function sql_command_str(sql_pattern, input)
   local i = 0
   local function ret_one()
      i = i + 1
      return input[i] or "NULL"
   end
   return string.gsub(sql_pattern, "[?]", ret_one)
end

return sql_command_str
