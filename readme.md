# Database
This has also already been written but needs to conform to this idea of an
API.

An sql table searcher would have:

* `.new{db=database}`
* `:compile(sql_command)` returning an object that is callable to
  effectively `:exec` it with commands.
* `:exec(sql_command, args)`

If `:compile(..)` actually does something, then one can consider memoizing it.
Otherwise it is just convenient accessing of commands.

* To `.new` add `repl=` replacements in the commands and `cmds=`
  a key-value store with either string(just replace stuff) or function
  (return the string with the object as input) values.
* `:cmd(name)` calls the command, and memoizes the corresponding
  `:compile` result.

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
* `:search(parsed_list)` actually does a search, changing the state of the thing.
* `:finish()` finishes the searching, adding some sorting and stuff, if specified.
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
* `:finish`, `:sql_pattern`, `:sql_values` in there.
* `:sql(search_string)` produces SQL code.
* `:result(search_string)` executes it aswel.

# TODO

* Maybe.. The Formulator inputs should just work with pattern + list of
  parameters instead of something  talking to the class.
