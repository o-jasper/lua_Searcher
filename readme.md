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

## Depreciated
Particularly, `Formulator` and `parsed_list` some stuff below it. Poor choice
not going full trees internally, and can do neater description of tables, with
concept of tables referring to tables etcetera.

Formulator is to be replaced with what is now in the TableMake branch.

# Installing
Either add the package directory to `package.path` or
symlink `package_dir/Searcher/` into someting accessible from `package.path`.

Depends on [luasql](https://github.com/keplerproject/luasql) for regular lua,
luajit currently needs to use the FFI bindings that are in this repo.
(segfaults so far..)

# TODO

* Was a formulator here, which is no

**Some parts anew;**
  + "tree" based statements on lua end. (*knew* i shouldah...)

    The searcher-from search-term based on that.

    A subset of these will be filters as per
    [this idea](http://ojasper.nl/blog/software/2015/11/12/libre_bus.html).

  + Derive from the general Sql object, making a "special" one that
    manages its collumns, adding them as needed.

    And has its own concept of "an object with a list/table attached".

    Basically do a lot of stuff now-done manually automatically.

* Luajit version segfaults.

* Get luakit variant to work too.

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
