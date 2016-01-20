-- Makes luasql behave the same as the luakit one.

local string_split = require "Searcher.util.string_split"

local sqlite3 = require("luasql.sqlite3").sqlite3("")

local Sql = {}

function Sql:new(new)
   new = setmetatable(new, self)
   new:init()
   return new
end

function Sql:init()
   self.db = sqlite3:connect(self.filename)
end

-- NOTE: high security risk zone.
function Sql:command_string(sql_command, args)  -- TODO question marks and arguments..
   if not args or #args == 0 then return sql_command end
   local command_str = ""
   local parts = string_split(sql_command, "?")
   assert( #args == #parts - 1, string.format("Wrong number of arguments %d != need %d",
                                              #args, #parts - 1))
   local command_str, j = "", 1
   while j < #parts do
      -- This is why here; it comes with escaping.
      local val = args[j]
      if type(val) == "string" then
         val = "'" .. self.db:escape(tostring(args[j])) .. "'"
      end
      command_str = command_str .. parts[j] .. tostring(val)
      j = j + 1
   end
   command_str = command_str .. parts[j]
   return command_str
end

function Sql:_cursor(command_str)
   local cursor = self.db:execute(command_str)
   if cursor then
      return cursor
   else  -- Close it and try again.
      self.db:close()
      self.db = sqlite3:connect(self.filename)
      return self.db:execute(command_str)
   end
end

function Sql:cursor(sql_command, args)
   return Sql._cursor(self, Sql.command_string(self, sql_command, args))
end

-- Produces an entire list immediately.
local function list_cursor(cursor)
   if not cursor or type(cursor) == "number" then return {} end

   local ret, new = {}, {}
   while cursor:fetch(new, "a") do
      table.insert(ret, new)
      new = {}
   end
   cursor:close()
   return ret
end

function Sql:exec(sql_command, ...)
   return list_cursor(Sql._cursor(self, Sql.command_string(self, sql_command, {...})))
end

return Sql
