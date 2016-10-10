--  Copyright (C) 20-04-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local sql_filters = require "Searcher.TableMake.sql_filters"
local maclike = require "Searcher.util.maclike"

local This = require("Searcher.util.Class"):class_derive{ __name="FilterSql" }

function This:init()
   self._sql, self._search, self._delete = {}, {}, {}
end

function This:sql(kind)
   assert(self.kinds)

   local ret = maclike(
      {depth=0, kind=kind, kind_name=kind.name, kinds=self.kinds},
      sql_filters,
      self)
   if type(ret) ~= "string" then
      for k,v in pairs(self) do print(k, type(k),v) end
      print("PRE",  unpack(self))
      print("POST", unpack(ret))
      print(ret[1], sql_filters[ret[1]], self[1], sql_filters[self[1]])
      error()
   end
   return ret
end

-- TODO filters selecting subset of kinds.
function This:search_sql(kind)
   local statement = self:sql(kind)
   statement = statement == "TRUE" and "" or " d0 WHERE\n" .. statement

   local sql = "SELECT * FROM " .. kind.sql_name .. statement

   local order_by = self.order_by or kind.pref_order_by or "false"
   if order_by == "default" then
      order_by = kind.pref_order_by or "false"
   end
   if order_by ~= "false" then
      sql = sql .. "\nORDER BY " .. order_by .. (self.desc and " DESC" or "")
   end
   local limit_cnt = self.limit_cnt or kind.pref_limit_cnt or -1
   if limit_cnt >=0 then
      sql = sql .. "\nLIMIT " .. (self.limit_from or 0) .. " " .. limit_cnt
   end
   return sql .. ";"
end

local function This_search_fun(self, kind)
   local search = self._search[kind.name]
   if not search then
      search = kind.db:compile(self:search_sql(kind))
      self._search[kind.name] = search
   end
   return search
end
This.search_fun = This_search_fun
function This:search(kind, ...)
   return This_search_fun(self, kind)(...)
end

function This:delete_sql(kind)
   local sql = "DELETE FROM " .. kind.sql_name "\n WHERE"
   return sql .. filter_sql(kind, self)
end

function This:delete_fun(kind)
   local delete = self._delete[kind.name]
   if not delete then
      delete = kind.db:compile(self:delete_sql(kind))
      self._delete[kind.name] = delete
   end
   return delete
end

function This:delete(kind, ...) return self:delete_fun(kind)(...) end

return This
