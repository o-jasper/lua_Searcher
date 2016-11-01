--  Copyright (C) 25-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local sql_filters = require "Searcher.db.Sql.Filter.raw.filters"

local maclike = require "Searcher.util.maclike"

local This = require("Searcher.util.Class"):class_derive{ __name="Just Sql String"}

This.description = "Just generates the SQL string, no actual searching"

function This:sql(kind)
   assert(self.kinds and kind)
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

   local order_by = self:figure_order_by(kind)
   if order_by ~= "false" then
      sql = sql .. "\nORDER BY " .. order_by .. (self.desc and " DESC" or "")
   end
   local limit_cnt = self:figure_limit_cnt(kind)
   if limit_cnt >=0 then
      sql = sql .. "\nLIMIT " .. (self.limit_from or 0) .. " " .. limit_cnt
   end
   return sql .. ";"
end

return This
