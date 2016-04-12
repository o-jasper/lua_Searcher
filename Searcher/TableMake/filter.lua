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

local function sql_search_1(kind, fun, tagged, combine)
   local subret = {}
   for _,el in ipairs(kind) do
      if el[tagged] then  -- Searchable entry.
         if el[2] == "string" then
            table.insert(subret, fun(el))
         elseif el[2] == "ref" then  -- Go down one.
            table.insert(subret,
                         sql_search_1(kind.self.kinds[el[3]], fun, tagged, combine))
         end
      end
   end
   -- Exists in sub-entry.
   local function sub_exists(subkind_name, from_id_name)
      local subkind = kind.self.kinds[subkind_name]
      local ins_sql = sql_search_1(subkind, fun, tagged, combine)
      local sql = "\n (EXISTS (SELECT * FROM " .. subkind.sql_name .. " WHERE\n" ..
         (from_id_name or "from_id") .. " == " .. kind.sql_var .. ".id AND\n" ..
         ins_sql .. "))"
      if ins_sql ~= "()" then
         table.insert(subret, sql)
      end
   end
   for _, el in ipairs(kind.ref_self or {}) do  -- In things referring to this.
      if el[tagged] then sub_exists(unpack(el, 2,3)) end
   end
   for _, el in ipairs(kind.key_self or {}) do  -- In things referring to this with key.
      if el[tagged] then
         local _, keyself_kind_name, from_id_name = unpack(el)
         sub_exists(keyself_kind_name, from_id_name)
      end
   end
   return  "(" .. table.concat(subret, combine) .. ")"
end

local function between(between_str, assert_n, filterfun)
   return function(kind, filter)
      assert(not assert_n or #filter == (assert_n + 1))
      local ret = {}
      for i = 2, #filter do
         local el = filter[i]
         table.insert(ret, filterfun(kind, el))
      end
      return "(" .. table.concat(ret, between_str) .. ")"
   end
end

local function use_search_1(fun, tagged, search_1, combine)
   return function(kind, filter)
      local ret = {}
      for i, f in ipairs(filter) do
         if i > 1 then
            table.insert(ret, search_1(kind, function(el) return fun(f, el) end,
                                       tagged, combine))
         end
      end
      return "(" .. table.concat(ret, combine) .. ")"
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
      "searchable", sql_search_1, " OR "),
}

local filter_lua_funs = {}
local function filter_lua(kind, filter)
   if type(filter) == "table" then
      local fun = filter_lua_funs[filter[1]]
      assert(fun, string.format("Don't have function named %s", filter[1]))
      return fun(kind, filter)
   elseif type(filter) == "string" then
      return "'" .. filter .. "'"
   else
      return tostring(filter)
   end
end

--

local function lua_search_1(kind, fun, tagged, combine)
   local subret = {}
   for _,el in ipairs(kind) do
      if el[tagged] then  -- Searchable entry.
         if el[2] == "string" then
            table.insert(subret, fun(el))
         elseif el[2] == "ref" then  -- Go down one.
            table.insert(subret, lua_search_1(kind.self.kinds[el[3]],
                                              fun, tagged, combine))
         end
      end
   end
   -- Exists in sub-entry.
   local function sub_exists(var_name, subkind_name, key_name)
      local subkind = kind.self.kinds[subkind_name]

      local key_stuff = key_name and
         string.format("%s.%s = key", subkind.sql_var, key_name)

      local listkeys, listvals = {}, {}
      for _, el in ipairs(subkind) do
         if el[1] ~= key_name then
            table.insert(listkeys, el[1])
            table.insert(listvals, subkind.sql_var .. "." .. el[1])
         end
      end

      local code = string.gsub([[(function()
  local list = {%oldvar}.{%var_name}
  for {%key_name}, {%var} in ipairs(list) do
    local {%listkeys} = {%listvals}
    if {%sub_search}  then
      return true
    end
  end
end)()]], "{%%([%w_]+)[%s]*([^}]*)}", {
            listkeys = table.concat(listkeys, ","),
            listvals = table.concat(listvals, ","),
            key_name = key_name or "_",
            oldvar = kind.sql_var,
            var = subkind.sql_var, var_name = key_name and var_name or "ref_self",
            old_var = kind.sql_var,
            sub_search = lua_search_1(subkind, fun, tagged, combine),
            key_stuff = key_stuff or " "
      })
      table.insert(subret, code)
   end
   for _, el in ipairs(kind.ref_self or {}) do  -- In things referring to this.
      if el[tagged] then sub_exists(unpack(el)) end
   end
   for _, el in ipairs(kind.key_self or {}) do  -- In things referring to this with key.
      if el[tagged] then
         local var_name, keyself_kind_name, _, key_name = unpack(el)
         sub_exists(var_name, keyself_kind_name, key_name or "key")
      end
   end
   return  "(" .. table.concat(subret, combine) .. ")"
end

filter_lua_funs = {
   ["and"] = between(" and "),
   ["or"]  = between(" or "),
   ["not"] = function(kind, filter) return "(not " .. filter_sql(kind, filter[2]) .. ")" end,

   sql_like = between(" LIKE ", 2),

   ["="] = between(" = "),  ["=="] = between(" == "),
   [">"] = between(" > "),  ["<"]  = between(" < "),
   [">="] = between(" >= "),["<="] = between(" <= "),

   ["+"] = between(" + "),  ["-"] = between(" - "),
   ["*"] = between(" * "),  ["/"] = between(" / "), ["%"] = between(" % "),

   search = use_search_1(function(f, el)
         return string.format([[string.find(%s, ".%s.")]], el[1], f)
      end,
      "searchable", lua_search_1, " and "),
}

return {filter_sql = filter_sql, run_filter=run_filter,
        filter_lua = filter_lua,
}
