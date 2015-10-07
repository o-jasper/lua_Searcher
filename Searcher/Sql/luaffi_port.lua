local ffi = require "ffi"
local sql3 = require "Searcher.Sql.luaffi"

local This = {}
This.__index = This

local code = sql3.code
local OK, DONE, ROW, BUSY = code.OK, code.DONE, code.ROW, code.BUSY
local FLOAT, INTEGER, TEXT = code.CODE, code.INTEGER, code.TEXT

function This:new(new)
   new = setmetatable(assert(new), self)
   new:init()
   return new
end
function This:init()
   self.cdata_ptr = ffi.new("sqlite3*[1]")
   local err = sql3.open(self.filename, self.cdata_ptr)
   self.cdata = self.cdata_ptr[0]
   self.err = (err ~= OK and err) or nil
end

local function rawcall(stmt, input)
   local cdata = stmt
   assert(sql3.bind_parameter_count(cdata) == #input)  -- Seems to crash here already?
   for i, el in ipairs(input) do  -- Put in values.
      el = tonumber(el) or el
      if type(el) == "string" then
         sql3.bind_text(cdata, i, el, #el, nil)
      elseif el == nil then
         sql3.bind_null(cdata, i)
      elseif not type(el) == "number" then
         error(string.format("Dunno what to do with type: %s", type(el)))
      else
         if el%1 == 0 then
            sql3.bind_int(cdata, i, el)
         else
            sql3.bind_double(cdata, i, el)
         end
      end
   end

   local rc, ret = sql3.step(cdata), {}
   local function grabstep()  -- Grabs a row.
      while rc == ROW do
         local here = {}
         for i = 0, sql3.column_count(cdata) - 1 do
            local tp, got = sql3.column_type(cdata, i), nil
            if tp == FLOAT then
               got = tonumber(sql3.column_double(cdata, i))
            elseif tp == INTEGER then
               got = tonumber(sql3.column_int64(cdata, i))
            elseif tp == TEXT then
               got = ffi.string(sql3.column_text(cdata, i))
            end
            here[ffi.string(sql3.column_name(cdata, i))] = got
         end
         table.insert(ret, here)

         rc = sql3.step(cdata)
      end
      return rc  -- Return whatever remains.
   end

   -- While grabbing rows, BUSY is allowed.
   while grabstep() == BUSY do end

   -- At end must be done, or must be some error.
   if rc ~= DONE then
      print("ERR", rc, unpack(sql3.invcode[rc]))
      return
   end
   return ret
end

-- Makes a statement.
local function rawprep(cdata, statement)
   local cdata_ptr = ffi.new("sqlite3_stmt*[1]")
   --print("***", cdata_ptr, cdata_ptr[0], statement)
   local pzTail = ffi.new("const char*[1]")  --TODO
   local rc = sql3.prepare_v2(cdata, statement, #statement + 1, cdata_ptr, pzTail)
   assert(rc == OK)
   return cdata_ptr
end

function This:compile(statement)
   assert(sql3.complete(statement) ~= 0, "Incompete:\n" .. statement)
   local cdata = rawprep(self.cdata, statement)
   return function(...)
      local ret = rawcall(cdata[0], {...})
      assert( sql3.reset(cdata[0]) == OK )
      assert( sql3.clear_bindings(cdata[0]) == OK )
      return ret
   end
end

function This:exec(statement, ...)
   assert(sql3.complete(statement .. ";") ~= 0)
   local cdata = rawprep(self.cdata, statement .. ";")
   local ret = rawcall(cdata[0], {...})
   assert( sql3.finalize(cdata[0]) == OK )  -- This one is destroyed.
   return ret
end

return This
