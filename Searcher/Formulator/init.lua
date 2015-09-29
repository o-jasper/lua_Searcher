--  Copyright (C) 14-08-2015 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

-- TODO taggings can be used for similar purposes..
--  Likely good to rename the concept, and have ability to use the concept
--   multiple times, the same way.

local Formulator = {}
Formulator.__index = Formulator
Formulator.__name = "SearcherS.Formulator"

-- Important: gotta be a _new_ one!
-- Note: use this is you want to "build" a search.
-- Otherwise the state is hanging around. (you can use it just the same)
function Formulator:new(new)  -- TODO rename to `copy`
   new = setmetatable(new or {}, self)
   new:init()
   return new
end

function Formulator:init()
   self.values = self.values or {}
   -- TODO multiple table names? 
   self.input = {}
   self.initial = nil
   if self.next_c ~= false then
      self.next_c = self.next_c or "WHERE"
   end
   self.c = self.c or "AND"
   if not self.cmd then
      self.cmd = {}
      self:select_table()
   end
   return self
end

function Formulator:include(input)
   for _, el in ipairs(input.cmd) do
      table.insert(self.cmd, el)
   end
   for _, el in ipairs(input.input) do
      table.insert(self.input, el)
   end
end

-- Stuff to help me construct queries based on searches.
function Formulator:extcmd(str, ...)
   if self.next_c then
      table.insert(self.cmd, self.next_c)
      self.next_c = false
   else
      table.insert(self.cmd, self.c)
   end
   table.insert(self.cmd, string.format(str, ...))
end
-- A piece of input.
function Formulator:inp(what)
   if type(what) ~= "table" then
      what = tostring(what)
   end
   assert(type(what) == "string",
          string.format("E(BUG): Not a string %s", what))
   table.insert(self.input, what)
end
-- Manually add string.
function Formulator:addstr(str, ...)
   self.cmd[#self.cmd] = self.cmd[#self.cmd] .. string.format(str, ...)
end

-- Selecting.
function Formulator:select_table(table_name)
   table.insert(self.cmd, string.format([[SELECT * FROM %s %s]],
                   table_name or self.values.table_name or "main",
                   self.values.mainvar or "m"))
end

-- Checks if things not being sneaked in via names.
local function value_check(which)
   return #which < 128 and string.find(which, "^[%w_]+$")
end

-- Lots of stuff to build searches from.
function Formulator:equal_1(which, input, invert)
   if value_check(which) then
      assert(type(input) == "string")
      self:extcmd("%s%s == ?", invert and "NOT " or "", which)
      self:inp(input)
   end
end

function Formulator:equal_list(which, input, invert)
   assert(type(input) == "table")
   local str = {string.format("%s%s IN (?", invert and "NOT " or "", which)}
   for i, f in pairs(input) do
      self:inp(f)
      if i ~= 1 then table.insert(str, "?") end
   end
   self:extcmd(table.concat(str, ", ") .. ")")
end

function Formulator:equal(which, input, invert)
   if value_check(which) then
      if type(input) == "table" then
         if #input > 1 then return self:equal_list(which, input, invert) end
         input = input[1]
      end
      return self:equal_1(which, input, invert)
   end
end

-- Value less/greater then ..  TODO or-equal?
function Formulator:lt(which, value)
   if value_check(which) then
      self:extcmd([[%s < ?]], which)
      self:inp(value)
   end
end
function Formulator:gt(which, value)
   if value_check(which) then
      self:extcmd([[%s > ?]], which)
      self:inp(value)
   end
end
-- Time is after/before ..
function Formulator:after(time)
   self:gt(self.values.time or "time", time)
end
function Formulator:before(time)
   self:lt(self.values.time or "time", time)
end

-- Add a like command.
function Formulator:like(which, value, invert)
   if value_check(which) then
      self:extcmd([[%s %sLIKE ?]], which, invert and "NOT " or "")
      self:inp(value)
   end
end
function Formulator:not_like(which, value)
   return self:like(which, value, true)
end

-- a LIKE command on all textlike parts.
function Formulator:text_like(search, n)
   for i, which in pairs(self.values.textlike) do
      self:like(which, search, n)
   end
end

-- Search word any textlike. (does that LIKE command with '%' around)
function Formulator:text_sw(search, n)
   if #search > 0 then
      self:text_like('%' .. search .. '%', n)
   end
end

Formulator.match_funs = {}

function Formulator.match_funs:default(state, m, text)
   if text and #text > 0 then
      return self:text_sw(text)
   end
end

-- Any exact tag.
function Formulator:tags(tags, taggingsname, tagname, w)
   if #tags == 0 then return end
   --         self:addstr("\nJOIN %s t ON t.to_id == m.id AND %s (",
   --                     taggingsname or self.values.taggings, w or "")
   
   local cmd = string.format([[%sEXISTS (
SELECT * FROM %s
WHERE to_id == m.id]], w or "", taggingsname or self.values.taggings or "tags")
   local f = Formulator:new{cmd = {cmd}, next_c=false} --:copy({c="AND", c_next=false})
   f:equal(tagname or self.values.tagname or "name", tags)
   f:addstr(")")
   self:include(f)
end

function Formulator:not_tags(tags, taggingsname, tagname)
   self:tags(tags, taggingsname, tagname, "NOT ")
end

-- The actual search build from it.
function Formulator:search(parsed_list)
   local state = {n=false, tags={}, not_tags={}, before_t=nil, after_t=nil, reset=true}
   local match_funs = self.match_funs
   
   for i, el in pairs(parsed_list) do
      local fun = match_funs[el.m] or match_funs.default
      assert(type(fun) == "function",
             string.format("Dont have a function for el.m; %s", el.m))
      fun(self, state, el.m, el.v)
   end
   self:tags(state.tags)
   self:not_tags(state.not_tags)

   if before_t then self:before(state.before_t) end
   if after_t  then self:after(state.after_t) end

   if state.order_by then
      self.dont_auto_order = true
      self:order_by(state.order_by, state.order_by_way)
   end
end

-- Sorting it.
function Formulator:order_by(what, way)
   if type(what) == "table" then what = table.concat(what, ", ") end
   self.c = ""
   self:extcmd("ORDER BY %s %s", what, way or "DESC")
end

function Formulator:auto_by(self)
   if self.values.order_by then
      self:order_by(self.values.order_by, self.values.order_way)
   end
end

-- Limiting the number of results.
function Formulator:limit(fr, cnt) 
   self.c = ""
   self.next_c = ""
   self:extcmd("LIMIT ?, ?")
   self:inp(fr)
   self:inp(cnt)
end

function Formulator:finish()  -- Add requested searches.
   if self.got_limit then  -- TODO tags here instead?..
      if #self.got_limit == 2 then
         self:limit(unpack(self.got_limit))
      else
         self:limit(0, self.got_limit[1])
      end
      self.got_limit = nil
   end
end

function Formulator:sql_pattern()
   self:finish()
   return table.concat(self.cmd, "\n") 
end

function Formulator:sql_values()
   return self.input
end

local parsed_list = require "Searcher.parsed_list"
function Formulator:search_str(str)
   local list = parsed_list(self.matchable, str)
   assert(self.matchable, "Need to indicate what keywords count.")
   return self:search(list)
end

return Formulator
