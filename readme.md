# Database
An sql table searcher with:

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

### Parsing
This should be entirely separate, with no idea of the database or
the previous section.

* `parsed_list(matchable, search_string)` take the *parsed list* and produce sql

  `matchable` is.. TODO document how to take that apart.

### Formulating
A function should take already-parsed queries and turn them into sql.
This should have no idea about the db *or* the parsing.

* `Formulator.new({values=, initial=, match_funs=..})` &rarr; `f` where `values`
  indicates things for defaults,
  `initial` is the initial sql command to start with.
   + `values.order_by` indicates how to order defaultly, `values.order_way`
     the direction(`"ASC"` or `"DESC"`, default latter)
* `f:search(parsed_list)` "adds a search".
* `f:finish()` finishes the query creation adding some sorting and stuff, if specified.
* `f:sql_pattern()` returns the sql_pattern at that point.
* `f:sql_values()` returns the values at that point.
* ... many more, that are specific to creating `match_funs`

At this point queries dont do the full range, but `match_funs` can be filled
to do arbitrary stuff in principle.

**TODO** an example putting it together.

# Installing
Either add the package directory to `package.path` or
symlink `package_dir/Searcher/` into someting accessible from `package.path`.

Depends on [luasql](https://github.com/keplerproject/luasql) for regular lua,
luajit currently needs to use the FFI bindings that are in this repo.
(segfaults so far..)

Luakit has its own variant too.

# TODO

* Luajit version segfaults.

* Get luakit variant to work too.

* Readme improvement?`
    
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
