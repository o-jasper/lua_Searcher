
-- TODO kindah want this accessible non-raw.

local kind_code = require "Searcher.db.Sql.raw.kind_code"

local function table_sql(kind)
   -- The `db` thing is just to placiate it...
   local kind = kind_code.prep({ cmd_strs={} }, kind, "tm_")
   -- TODO want this text somehow available?
   return kind_code.create_table_sql(kind)
end

print(table_sql {
	 name="user",
	 { "username", "text"},
	 { "password_hash", "string"}, {"full_name", "text"}, { "email", "text" },
	 { "department", "ref", "department", searchable=true}
})
