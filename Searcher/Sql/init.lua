-- * Strips a lot of distracting features from the port.
-- * Adds the command thingy.

local Sql_port
pcall(function() Sql_port = require "Searcher.Sql.luasql_port" end)
if not Sql_port then
   Sql_port = require "Searcher.Sql.LJIT2SQLite"
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

return Sql
