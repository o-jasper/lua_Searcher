--  Copyright (C) 25-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local sql_filters = require "Searcher.db.Sql.Filter.raw.filters"
local EntryMeta = require "Searcher.db.Sql.Filter.raw.EntryMeta"

local maclike = require "Searcher.util.maclike"

local This = require("Searcher.util.Class"):class_derive{ __name="Searcher.db.Sql.Filter" }

This.description = [[Sql filter object, the creator specifies the search term.
Better create via `Searcher.db.Sql`.]]

function This:init()
   self._sql, self._search, self._delete = {}, {}, {}
end

function This:sql(kind)
   assert(self.kinds)
   assert(kind)
   return maclike(
      {depth=0, kind=kind, kind_name=kind.name, kinds=self.kinds},
      sql_filters,
      self)
end

-- TODO filters selecting subset of kinds.
function This:search_sql(kind_name)
   local kind = assert(self.kinds[kind_name], "Could not figure kind: " .. kind_name)
   local statement = self:sql(kind)
   statement = (statement == "TRUE" and "" or " d0 WHERE\n") .. statement

   local sql = "SELECT * FROM " .. kind._sql_name .. statement

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

local function This_search_fun(self, kind_name)
   assert(type(kind_name) == "string")
   local search = self._search[kind_name]
   if not search then
      search = self.db:compile(self:search_sql(kind_name))
      self._search[kind_name] = search
   end
   return search
end
This.search_fun = This_search_fun
function This:search(kind_name, ...)
   return This_search_fun(self, kind_name)(...)
end

function This:full_access(kind_name, list)
   for _, el in ipairs(list) do
      EntryMeta.new_1(self, kind_name, el)
   end
   return list
end

function This:accessible_search(kind_name, ...)
   return self:full_access(kind_name, self:search(kind_name, ...))
end

function This:delete_sql(kind_name)
   local kind = self.kinds[kind_name]
   local sql = "DELETE FROM " .. kind._sql_name .. "\n WHERE"
   return sql .. self:sql(kind)
end

function This:delete_fun(kind_name)
   local delete = self._delete[kind_name]
   if not delete then
      delete = self.db:compile(self:delete_sql(kind_name))
      self._delete[kind_name] = delete
   end
   return delete
end

function This:delete(kind, ...) return self:delete_fun(kind)(...) end

return This
