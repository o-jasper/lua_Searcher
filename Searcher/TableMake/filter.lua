local filter_sql_funs = {}
local function filter_sql(kind, filter)
   if type(filter) == "table" then
      local fun = filter_sql_funs[filter[1]]
      assert(fun, string.format("Don't have function named %s", filter[1]))
      return fun(kind, filter)
   elseif type(filter) == "string" then
      return "'" .. filter .. "'"
   else
      return tostring(filter)
   end
end 

local function search_1(kind, fun, tagged)
   local subret = {}
   for _,el in ipairs(kind) do
      if el[tagged] then  -- Searchable entry.
         if el[2] == "string" then
            table.insert(subret, fun(el))
         elseif el[2] == "ref" then  -- Go down one.
            table.insert(subret, search_1(kind.self.kinds[el[3]], fun, tagged))
         end
      end
   end
   -- Exists in sub-entry.
   local function sub_exists(subkind_name, from_id_name)
      local subkind = kind.self.kinds[subkind_name]
      local sql = "\n EXISTS ( SELECT * FROM " .. subkind.db_name .. "\n" ..
         (from_id_name or "from_id") .. " == " .. kind.sql_var .. ".id AND\n" ..
         search_1(subkind, fun, tagged) .. ")"
   end
   for _, el in ipairs(kind.ref_self) do  -- In things referring to this.
      if el[tagged] then sub_exist(unpack(el, 2,3)) end
   end
   for _, el in ipairs(kind.key_self) do  -- In things referring to this with key.
      if el[tagged] then
         local _, keyself_kind_name, _, from_id_name = unpack(el)
         sub_exist(keyself_kind_name, from_id_name)
      end
   end
   return table.insert(ret, "(" .. table.concat(subret, " OR ") .. ")")   
end

local function between(between_str, assert_n)
   return function(kind, filter)
      assert(not assert_n or #filter == (assert_n + 1))
      local ret = {}
      for i = 2, #filter do
         local el = filter[i]
         table.insert(ret, filter_sql(kind, el))
      end
      return "(" .. table.concat(ret, between_str) .. ")"
   end
end

local function use_search_1(fun, tagged)
   return function(kind, filter)
      local ret = {}
      for _, f in ipairs(filter) do
         table.insert(ret, search_1(kind, function(el) return fun(f, el) end, tagged))
      end
      return "(" .. table.concat(ret, " AND ") .. ")"
   end
end

filter_sql_funs = {
   ["and"] = between(" AND "),
   ["or"]  = between(" OR "),
   ["not"] = function(kind, filter) return "(NOT " .. filter_sql(kind, filter[2]) .. ")" end,

   sql_like = between(" LIKE ", 2),

   ["="] = between(" = "),  ["=="] = between(" == "),
   [">"] = between(" > "),  ["<"]  = between(" < "),
   [">="] = between(" >= "),["<="] = between(" <= "),

   ["+"] = between(" + "),  ["-"] = between(" - "),
   ["*"] = between(" * "),  ["/"] = between(" / "), ["%"] = between(" % "),

   search = use_search_1(function(f, el) return el[1] .. " LIKE '%" .. f .. "%'" end,
      "searchable"),
}


-- Run filter directly.
local run_filter_funs
local function run_filter(kind, filter, data)
   return run_filter_funs[filter[1]](kind, filter, data)
end

--local function run_on_1(kind, fun, tagged)
--   local subret = {}
--   for _,el in ipairs(kind) do
--      if el[tagged] then  -- Searchable entry.
--         if el[2] == "string" then
--            table.insert(subret, fun(el))
--         elseif el[2] == "ref" then  -- Go down one.
--            table.insert(subret, search_1(kind.self.kinds[el[3]], fun, tagged))
--         end
--      end
--   end
--   -- Exists in sub-entry.
--   local function sub_exists(subkind_name, from_id_name)
--      local subkind = kind.self.kinds[subkind_name]
--      local sql = "\n EXISTS ( SELECT * FROM " .. subkind.db_name .. "\n" ..
--         (from_id_name or "from_id") .. " == " .. kind.sql_var .. ".id AND\n" ..
--         search_1(subkind, fun, tagged) .. ")"
--   end
--   for _, el in ipairs(kind.ref_self) do  -- In things referring to this.
--      if el[tagged] then sub_exist(unpack(el, 2,3)) end
--   end
--   for _, el in ipairs(kind.key_self) do  -- In things referring to this with key.
--      if el[tagged] then
--         local _, keyself_kind_name, _, from_id_name = unpack(el)
--         sub_exist(keyself_kind_name, from_id_name)
--      end
--   end
--   return table.insert(ret, "(" .. table.concat(subret, " OR ") .. ")")   
--end

run_filter_funs = {
   ["and"] = function(kind, filter, data)
      for i = 2,#filter do
         local x = filter[i]
         if not run_filter[x[1]](kind, x, data) then return false end
      end
      return true
   end,
   ["or"] = function(kind, filter, data)
      for i = 2,#filter do
         local x = filter[i]
         if run_filter[x[1]](kind, x, data) then return true end
      end
      return false
   end,
   ["not"] = function(...) return not run_filter(...) end,

   ["="]  = function(_, x, data) return x == data end,
   ["=="] = function(_, x, data) return x == data end,
   [">"]  = function(_, x, data) return x > data end,
   ["<"]  = function(_, x, data) return x < data end,
   [">="] = function(_, x, data) return x >= data end,
   ["<="] = function(_, x, data) return x <= data end,
   ["+"]  = function(_, x, data) return x + data end,
   ["-"]  = function(_, x, data) return x - data end,
   ["*"]  = function(_, x, data) return x * data end,
   ["/"]  = function(_, x, data) return x / data end,
   ["%"]  = function(_, x, data) return x % data end,

--   search  -- TODO it is trickier..
}

run_filter_funs["=="] = run_filter_funs["="]

local compile_filter 

return {filter_sql = filter_sql, run_filter=run_filter,
        compile_filter_str = compile_filter_str,
}
