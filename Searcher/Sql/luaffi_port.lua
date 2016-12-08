--  Copyright (C) 07-12-2016 Jasper den Ouden.
--
--  This is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published
--  by the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

local ffi = require "ffi"
local sql3 = require "Searcher.Sql.luaffi"

local This = require("Searcher.util.Class"):class_derive{ name="luaffi_port" }

local code = sql3.code
local OK, DONE, ROW, BUSY = code.OK, code.DONE, code.ROW, code.BUSY
local FLOAT, INTEGER, TEXT = code.FLOAT, code.INTEGER, code.TEXT

function This:init()
   self.cdata_ptr = ffi.new("sqlite3*[1]")
   local err = sql3.open(self.filename, self.cdata_ptr)
   self.cdata = self.cdata_ptr[0]
   self.err = (err ~= OK and err) or nil
end

local function raw_input(stmt, input)
   assert(sql3.bind_parameter_count(stmt) == #input)  -- Seems to crash here already?
   for i, el in ipairs(input) do  -- Put in values.
      el = tonumber(el) or el
      if type(el) == "string" then
         sql3.bind_text(stmt, i, el, #el, nil)
      elseif el == nil then
         sql3.bind_null(stmt, i)
      elseif not type(el) == "number" then
         error(string.format("Dunno what to do with type: %s", type(el)))
      else
         if el%1 == 0 then
            sql3.bind_int(stmt, i, el)
         else
            sql3.bind_double(stmt, i, el)
         end
      end
   end
end

function rawcall(stmt)
   print("->3")
   local rc, ret = nil, {}
   local j = 0
   while rc ~= DONE do
      j = j + 1
      rc = sql3.step(stmt)
      assert(({[DONE]=true, [ROW]=true})[rc])
      print("*--", j, unpack(sql3.invcode[rc]))
      if rc == ROW then -- Grabs a row.
         local here = {}
	 print("->", j, stmt)  -- TODO can it run out?
	 -- TODO seems like it segfaults simply from doing stuff.
	 print(sql3.data_count(stmt) - 1)
	 print("FEH")
         for i = 0, sql3.column_count(stmt) - 1 do
            local tp, got = sql3.column_type(stmt, i), nil
	    print(i, "==", tp, FLOAT, INTEGER, TEXT, got)
            if tp == INTEGER then
               got = tonumber(sql3.column_int64(stmt, i))
	    elseif tp == FLOAT then
	       got = tonumber(sql3.column_double(stmt, i))
            elseif tp == TEXT then
               got = ffi.string(sql3.column_text(stmt, i))
            end
            here[ffi.string(sql3.column_name(stmt, i))] = got
         end
         table.insert(ret, here)
      end
   end
   print("->4")
   -- At end must be done, or must be some error.
  return ret, rc
end

local list = {}
-- Makes a statement.
local function rawprep(cdata, statement)
   local stmt_ptr = ffi.new("sqlite3_stmt*[1]")
   local rc = sql3.prepare_v2(cdata, statement, #statement + 1, stmt_ptr, nil)
   assert(rc == 0, string.format("%s (%d)", sql3.invcode[rc][1], rc))
   print("-", stmt_ptr, stmt_ptr[0])  -- TODO stumpeningly, stays identical?
   return stmt_ptr
end

function This:compile(statement)
   print("COMPILE", statement)
   assert(sql3.complete(statement) ~= 0, "Incomplete:\n" .. statement)
   local stmt_ptr = rawprep(self.cdata, statement)
   return function(...)
      raw_input(stmt_ptr[0], {...})
      local ret = rawcall(stmt_ptr[0])
      assert( sql3.reset(stmt_ptr[0]) == OK )
      assert( sql3.clear_bindings(stmt_ptr[0]) == OK )
      return ret
   end
end
This.compile = nil

function This:exec(statement, ...)
   print("EXEC", statement, ...)
   assert(sql3.complete(statement .. ";") ~= 0)
   local stmt_ptr = rawprep(self.cdata, statement .. ";")
   print("->B", stmt_ptr[0])
   raw_input(stmt_ptr[0], {...})
   local ret, rc = rawcall(stmt_ptr[0])
   print("->A")
   assert( sql3.finalize(stmt_ptr[0]) == OK )  -- This one is destroyed.
   return ret
end

return This
