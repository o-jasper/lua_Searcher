-- TODO

--[[
** 2001 September 15
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
** 2015 October 06
**
**  Basically taken apart and put back together.
**
--]]


local ffi = require "ffi"

ffi.cdef(require "Searcher.Sql.luaffi.c_header")

local lib = ffi.load(ffi.os == "Windows" and "bin/sqlite3" or "sqlite3")

-- initialize the library
lib.sqlite3_initialize();

local sqlite3_list = require "Searcher.Sql.luaffi.fun_list"

local Public = {}
for _,el in ipairs(sqlite3_list) do
   Public[el] = lib["sqlite3_" .. el]
end

Public.code = require "Searcher.Sql.luaffi.codes_list"

Public.invcode = {}
for k,v in pairs(Public.code) do
   local got = Public.invcode[v] or {}
   table.insert(got, k)
   Public.invcode[v] = got
end

return Public
