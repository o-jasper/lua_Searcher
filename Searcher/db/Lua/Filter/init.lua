--  Copyright (C) 30-10-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the Afrero GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- Filter and conversion to lua that can handle the lua-table representation
-- of messages.

local This = require("Searcher.db.Lua.Filter.Base"):class_derive{ __name="Filter" }

return This
