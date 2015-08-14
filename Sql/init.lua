-- * Strips a lot of distracting features from the port.
-- * Adds the command thingy.

local Sql_port = require "sql_searcher.Sql.luasql_port"  -- TODO port the luakit one?
local apply_subst = require "o_jasper_common.apply_subst"

local Sql = { compile = Sql_port.compile, exec = Sql_port.exec }

function Sql.new(tab)
   return setmetatable(Sql_port.new(tab), Sql)
end

function Sql:cmd(name)
   local got = self.memoize[name]
   if got then return got end

   local str = self.cmds[name]
   if type(str) == "function" then
      got = ret(self, str)
   end
   local got = self:compile(apply_subst(ret, self.repl))
   self.memoize[name] = got
   return got   
end

return Sql
