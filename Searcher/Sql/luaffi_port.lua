local ffi = require "ffi"
local sql3 = require "Searcher.Sql.luaffi"

local This = {}
This.__index = This

function This:new(new)
   new = setmetatable(assert(new), self)
   new:init()
   return new
end
function This:init()
   self.cdata_ptr = ffi.new("sqlite3*[1]")
   local err = sql3.open(self.filename, self.cdata_ptr)
   self.cdata = self.cdata_ptr[0]
   self.err = (err ~= sql3.code.OK and err) or nil
end

local function rawcall(stmt, input)
   local cdata = stmt
   for i, el in ipairs(input) do
      if type(el) == "string" then
         sql3.bind_text(cdata, i, el, #el, nil)
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
   local function grabstep()
      while rc == sql3.code.ROW do
         -- Grab the row.
         local here = {}
         for i = 0, sql3.column_count(cdata) - 1 do
            local tp, got = sql3.column_type(cdata, i), nil
            if tp == sql3.code.FLOAT then
               got = sql3.column_double(cdata, i)
            elseif tp == sql3.code.INTEGER then
               got = sql3.column_int64(cdata, i)
            elseif tp == sql3.code.TEXT then
               got = ffi.string(sql3.column_text(cdata, i))
            end
            here[ffi.string(sql3.column_name(cdata, i))] = got
            --print(sql3.column_name(cdata, i))
         end
         table.insert(ret, here)

         rc = sql3.step(cdata)
      end
      return rc  -- Return whatever remains.
   end

   while grabstep() == sql3.code.BUSY do end

   if rc ~= sql3.code.DONE then
      print("ERR", rc, unpack(sql3.invcode[rc]))
      return
   end
   return ret
end

local function rawprep(cdata, statement)
   local cdata_ptr = ffi.new("sqlite3_stmt*[1]")
   local rc = sql3.prepare_v2(cdata, statement, #statement, cdata_ptr, nil)
   return cdata_ptr, cdata_ptr[0]
end

function This:compile(statement)
   local _, cdata = rawprep(self.cdata, statement)
   return function(...)
      local ret = rawcall(cdata, {...})
      sql3.reset(cdata)
      sql3.clear_bindings(cdata)
      return ret
   end
end

function This:exec(statement, ...)
   local _, cdata = rawprep(self.cdata, statement)
   local ret = rawcall(cdata, {...})
   sql.finish(data)  -- This one is destroyed.
   -- TODO free it?
   return ret
end

return This
