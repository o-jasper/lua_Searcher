local time_interpret_ms = require "Searcher.fromtext.time.interpret_ms"

local function time_interpret(str, from_t)
   local t_ms = time_interpret_ms(str, from_t)
   return t_ms and t_ms/1000
end

return time_interpret
