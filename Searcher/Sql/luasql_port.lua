--  Copyright (C) 27-01-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Makes luasql behave the same as the luakit one.

local string_split = require "Searcher.util.string_split"

local sqlite3 = require("luasql.sqlite3").sqlite3("")

local Sql = require("Searcher.util.Class"):class_derive{ name="Searcher.Sql.luasql_port"}

function Sql:init()
   self.db = sqlite3:connect(self.filename)
end

local sql_command_str = require "Searcher.Sql.command_str"

-- NOTE: high security risk zone.
function Sql:command_string(sql_pattern, args)  -- TODO question marks and arguments..
   if not args or #args == 0 then return sql_pattern end

   local function prep_string(str) return self.db:escape(tostring(str)) end
   return sql_command_str(sql_pattern, args, prep_string)
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

-- TODO iterating version?

return Sql
