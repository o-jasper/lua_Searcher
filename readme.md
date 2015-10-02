# Database
This has also already been written but needs to conform to this idea of an
API.

An sql table searcher would have:

* `Sql:new{filename=, db=..}` makes a new object, best to supply just `filename`,
  it'll get you the database.(-connection)
  `":memory:"` will make one in-memory.
* `:compile(sql_command)` returning an object that is callable to
  effectively `:exec` it with commands.
* `:exec(sql_command, args...)`

If `:compile(..)` actually does something, then one can consider memoizing it.
Otherwise it is just convenient accessing of commands.

* To `:new` add `repl=` replacements in the commands and `cmd_strs=`
  a key-value store with either string(just replace stuff) or function
  (return the string with the object as input) values.
* `:cmd(name)` calls the command, and memoizes the corresponding
  `:compile` result. (`.cmds[..]` or `.cmds.thing` works too)

### Parsing
This should be entirely separate, with no idea of the database or
the previous section.

* `parsed_list(matchable, search_string)` take the *parsed list* and produce sql

  `matchable` is.. TODO

### Formulating
A function should take already-parsed queries and turn them into sql.
This should have no idea about the db *or* the parsing.

* `Formulator.new({values=, initial=, match_funs=..})` where `values`
  indicates things for defaults,
  `initial` is the initial sql command to start with.
   + `values.order_by` indicates how to order defaultly, `values.order_way`
     the direction(`"ASC"` or `"DESC"`, default latter)
* `:search(parsed_list)` "adds a search".
* `:finish()` finishes the query creation adding some sorting and stuff, if specified.
* `:sql_pattern()` returns the sql_pattern at that point.
* `:sql_values()` returns the values at that point.
* ... many more, that are specific to creating `match_funs`

At this point queries are really simple objects, for more
complicated stuff, go to the sql code itself.

#### Searcher; throwing it together.

* `.new{db=, repl=, cmds=, matchable=, matchfuns=}`
  
  `matchable` is to be implied from `matchfuns`, except only to the extent that
  order-dependence matters.

* `:exec`, `:compile`, `:cmd` in there.
* `:search`, `:finish`. `sql_pattern`, `:sql_values` in there

* Only additional; `:result()` in there, finishing and executing the search.

# Installing
Either add the package directory to `package.path` or
symlink `package_dir/Searcher/` into someting accessible from `package.path`.

Depends on [luasql](https://github.com/keplerproject/luasql) for regular lua,
and TODO is using [LJIT2SQLite](https://github.com/Wiladams/LJIT2SQLite) for luajit.

Luakit has its own variant too.

# TODO

* Luajit needs port of [LJIT2SQLite](https://github.com/Wiladams/LJIT2SQLite).

* Get luakit variant to work too.

* Readme improvement?
    
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
