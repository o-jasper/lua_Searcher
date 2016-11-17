local Sql = require "Searcher.db.Sql"

local function inst(tab, name, ins)
   local list = tab[name] or {}
   tab[name] = list   
   table.insert(list, ins)
end

-- Uses a filter to search.
-- TODO  * Version of `:search` producing an iterator.
--       * Pumping to move the iterator?
local function search_op(name, filter, exit)
   for _, ret in ipairs(sql:filter(filter):search(name)) do
      exit.output(ret)  -- TODO KindMeta may need to be data-izable too.
   end
end

local get_more_kinds = true
local sql

local function insert(msg, exit, index)
   if not msg.kind then
      for k,v in pairs(msg) do print(k,v) end
   end
   assert(msg.kind)
   if get_more_kinds and not sql.kinds[msg.kind] then
      exit.kind(msg.kind, index + 1)  -- Ask if that kind exists.
      inst(behind.insert, msg.kind, msg) -- Insert later.
   else  -- Insert now.
      sql:insert(msg)
   end
end

return {
   init = function(msg)
      if type(msg) == "string" then
	 assert(not sql)
	 sql = Sql:new{ filename=msg }
      elseif type(msg) == "boolean" then
	 get_more_kinds = msg
      else
	 assert(type(msg) == "table" and msg.name)
	 sql:add_kind(msg)
      end	    
   end,
   finalize = function()
      if not sql then sql = Sql:new{ filename=":memory:" } end
      --if not get_more_kinds then change_stage("normal") end  -- TODO
      behind = { insert = {}, search = {}, delete = {} }
   end,

   -- TODO
   -- * You probably want to use returning for this, but it then the searching
   --   cannot use returning.
   -- * The order changes.
   -- Adds a kind, does backlog wrt that kind.
   kind = function(msg, exit)
      sql:add_kind(msg)  -- Add the kind.

      local name = msg.name  -- Catch up, inserts.
      for _, el in ipairs(behind.insert[name] or {}) do
	 sql:insert(el)
      end
      behind.insert[msg.name] = nil
      for _, filter in ipairs(behind.search[name] or {}) do  -- Catch up searches
	 search_op(name, filter, exit)
      end
      behind.search[msg.name] = nil
      for _, el in ipairs(behind.delete[name] or {}) do  -- Catch up deletes.
	 sql:filter(el):delete(name)
      end
      behind.delete[msg.name] = nil
   end,

   -- Inserts an entry.
   insert = insert,
   -- Insert and re-output.
   default = function(msg, exit, index)
      insert(msg, exit, index)
      exit.output(msg)
   end,

   search = function(msg, exit, index)  -- Searches an entity.
      if get_more_kinds and not sql.kinds[msg.kind] then
	 exit.kind(msg.kind, index + 1)
	 inst(behind.search, msg.kind, msg)
      else
	 search_op(msg.kind, msg, exit)
      end
   end,
   delete = function(msg)  -- Idem delete.
      if get_more_kinds and not sql.kinds[msg.kind] then
	 exit.kind(msg.kind, index + 1)
	 inst(behind.delete, msg.kind, msg)
      else
	 sql:filter(msg):delete(msg.kind)
      end
   end,
}
