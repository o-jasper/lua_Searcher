--  Copyright (C) 25-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local EntryMeta = require "Searcher.db.Sql.Filter.raw.EntryMeta"

local This = require("Searcher.db.raw.BaseFilter"):class_derive(
   require "Searcher.db.Sql.Filter.JustSqlString",
   { __name="Searcher.db.Sql.Filter" })

This.description = [[Sql filter object, the creator specifies the search term.
Better create via `Searcher.db.Sql`.]]

function This:init()
   self._search, self._delete = {}, {}
end

local function raw_search_fun(self, kind_name)
   assert(type(kind_name) == "string", kind_name)
   local search = self._search[kind_name]
   if not search then
      search = self.db:compile(self:search_sql(kind_name))
      self._search[kind_name] = search
   end
   return search
end
This.raw_search_fun = raw_search_fun
function This:raw_search(kind_name, ...)
   return raw_search_fun(self, kind_name)(...)
end

-- Makes them entrymetas of the data, which look up more information as needed.
function This:full_access(kind_name, list)
   for _, el in ipairs(list) do
      EntryMeta.new_1(self, kind_name, el)
   end
   return list
end

function This:search_fun(kind_name)
   return function(...)
      return self:full_access(kind_name, raw_search_fun(self, kind_name)(...))
   end
end

function This:search(kind_name, ...)
   return self:full_access(kind_name, raw_search_fun(self, kind_name)(...))
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
