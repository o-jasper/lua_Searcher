-- * Strips a lot of distracting features from the port.
-- * Adds the command thingy.

local Sql_port = require "Searcher.Sql.luasql_port"  -- TODO port the luakit one?
local apply_subst = require "o_jasper_common.apply_subst"

local Sql = { init = Sql_port.init, compile = Sql_port.compile, exec = Sql_port.exec }
Sql.__index = Sql

function Sql.new(self)
   self = setmetatable(self, Sql)
   self:init()
   self.repl = self.repl or {}
   self.cmd_strs = self.cmd_strs or {}
   local function index(_, key) return self:cmd(key) end
   self.cmds = setmetatable({}, { __index = index })
   self.memoize = self.memoize or {}
   return self
end

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
