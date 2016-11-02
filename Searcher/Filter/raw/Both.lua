-- NOTE: here FTR.. untested.

return require("Searcher.db.Lua.Filter"):class_derive(
   require "Searcher.db.Sql.Filter",
   { __name="FilterBoth" })

