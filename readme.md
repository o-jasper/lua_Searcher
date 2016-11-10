# "Kind" system and databases with filters
Different "kinds" are essentially sort-of struct-like things, for SQL
corresponding to a table, with specification what the entries mean.

Usage is:

* Create main object, I.e. `db = require("Searcher.db.Sql"):new{filename=":memory:"}`
* Add kinds `db:add_kind{...}` *TODO describe kind specification.*

* Make filters `filter = db:filter(filter)` filters are essentially just code
  described as nested lists. `{"search", "term1", "term2"}` is one command,
  `{"or", ...}` and `{"and", ...}` exist too. There is also still room to add more.

  + Results that use the DB for further accessing. `filter:access(kind_name)`
  + Plain results `filter:search(kind_name)`, only top level objects, integers may
    be references.
  + Deleting results `filter:delete(kind_name)`
  
  + `:..._sql(...)` gets the SQL that would do it. `:_..._fun(...)` returns a function that
    would.

   The reason you make a filter first and then specify for kinds, is because it is
   easier to memoize by kinds than by filter.

   All of kinds, filters, entries, are considered just data. The filter object is just
   a handle to that search.

Note that there is also `require "Searcher.db.Lua"`, which stores it in lua
tables. No cleverness, just "dumbly" searchers for it. No to-disc storage yet either.

Filters are also separate objects creatable via `require "Searcher.Filter"`.
(or the more specific ones)

# Database
Database available separate, of course.
[Luasql](https://github.com/keplerproject/luasql)
version works, there is a luajit one, but unfortunately it segfaults.
Hopefully more in the future.

API:

* `Sql:new{filename=, db=..}` &rarr; `s` makes a new object, best to supply just `filename`,
  it'll get you the database.(-connection)
  `"s:memory:"` will make one in-memory.
* `:compile(sql_command)` returning an object that is callable(like a function)
  to effectively `:exec` it with commands. (may memoize aspects of the action)
* `s:exec(sql_command, args...)`

* To `s:new` add `repl=` replacements in the commands and `cmd_strs=`
  a key-value store with either string(just replace stuff) or function
  (return the string with the object as input) values.
* `s:cmd(name)` calls the command, and memoizes the corresponding
  `s:compile` result. (`s.cmds[..]` or `s.cmds.thing` works too)

# Installing
Either add the package directory to `package.path` or
symlink `package_dir/Searcher/` into someting accessible from `package.path`.

Depends on [luasql](https://github.com/keplerproject/luasql) for regular lua,
luajit currently needs to use the FFI bindings that are in this repo.
(segfaults so far..)

# TODO

* Need filters from search-strings.

* Currently a macro-like system for generating the (sql/lua)code. A more general
  one is better/worse.

## Lua Ring

* [lua_Searcher](https://github.com/o-jasper/lua_Searcher) sql formulator including
  search term, and Sqlite bindings.

* [page_html](https://github.com/o-jasper/page_html) provide some methods on an object,
  get a html page.(with js)

* [storebin](https://github.com/o-jasper/storebin) converts trees to binary, same
  interfaces as json package.(plus `file_encode`, `file_decode`)
  
* [PegasusJs](https://github.com/o-jasper/PegasusJs), easily RPCs javascript to
  lua. In pegasus.

* [tox_comms](https://github.com/o-jasper/tox_comms/), lua bindings to Tox and
  bare bot.
