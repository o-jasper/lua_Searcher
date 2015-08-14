local Formulator = require "Searcher.Formulator"

local f = Formulator.new({values={textlike={"text"}}})

f:text_like("miauw")
f:lt("ska", 23)
f:after(535)

assert(f:sql_pattern() == [[SELECT * FROM main m
WHERE
text LIKE ?
AND
ska < ?
AND
time > ?]])

local f = Formulator.new({values={textlike={"text"}}})
f:text_like("miauw")
f:tags({"miauw", "mew"})

assert(f:sql_pattern() == [[SELECT * FROM main m
WHERE
text LIKE ?
EXISTS (
SELECT * FROM tags
WHERE to_id == m.id
AND
name IN (?, ?))]])
