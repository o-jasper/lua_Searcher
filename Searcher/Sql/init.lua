--  Copyright (C) 02-04-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- * Strips a lot of distracting features from the port.
-- * Adds the command thingy.

local Sql_port = nil

pcall(function() Sql_port = require "Searcher.Sql.luaffi_port" end)

if not Sql_port then
   pcall(function() Sql_port = require "Searcher.Sql.luasql_port" end)
end

local apply_subst = require "page_html.util.apply_subst"

local Sql = { compile = Sql_port.compile,
              exec = Sql_port.exec, exec_callback= Sql_port.exec_callback
}
Sql.__index = Sql
Sql.__name = "Searcher.Sql"

function Sql:new(new)
   new = setmetatable(new or {}, self)
   new:init()
   return new
end

function Sql:init()
   assert(self.filename)
   Sql_port.init(self)
   self.repl = self.repl or {}
   self.cmd_strs = self.cmd_strs or {}

   -- Fancy access.
   local function index(_, key) return self:cmd(key) end
   self.cmds = setmetatable({}, { __index = index })

   self.memoize = self.memoize or {}
end

if not Sql.compile then  -- Fake a compile.
   function Sql:compile(sql_cmd)
      return function(...) return self:exec(sql_cmd, ...) end
   end
end

if not Sql.exec_callback then
   function Sql:exec_callback(callback, sql_cmd, ...)
      callback(self:exec(sql_cmd, ...))
   end
end
--if not Sql.compile_callback then
--   function Sql:compile_callback(sql_cmd)
--      return function(callback, ...)
--         return self:exec_callback(callback, sql_cmd, ...)
--      end
--   end
--end

function Sql:cmd(name)
   local got = self.memoize[name]
   if got then return got end

   local str = self.cmd_strs[name]
   if type(str) == "function" then
      str = str(self, str)
   end
   if str then
      local got = self:compile(apply_subst(str, self.repl))
      self.memoize[name] = got
      return got
   end
end

--function Sql:class_cmd_add(name, sql)
--   self.cmd_strs[name] = sql
--end
--
--function Sql:class_cmd_add_w_fun(name, sql, fun_name)
--   self:class_cmd_add(name, sql)
--   self[fun_name or name] = function(s, ...) return s:cmd(name)(...) end
--end

return Sql
