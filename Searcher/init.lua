local Sql = require "Searcher.Sql"
local Formulator = require "Searcher.Formulator"

local Searcher = {}
for k,v in pairs(Sql)        do Searcher[k] = v end
for k,v in pairs(Formulator) do Searcher[k] = v end

Searcher.__name = "Searcher"
Searcher.__index = Searcher

function Searcher:init()
   Sql.init(self)
   Formulator.init(self)
end

return Searcher
