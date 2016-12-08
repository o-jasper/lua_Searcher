-- Try `curl localhost:9091/yourfiles` where the file in your home directory.

local mkprog = require "nunix.graph.mkprog"

local prog = mkprog{
   kind = {
      {"io.print"},
      {"kinds"},
      {"return"},
   },
   miss = {
      {"io.print"},
      {"http.endcap", true, "-- Could not find:\n{%whole_list}"},
      arg[1] == "loop" and {"go", "entry"} or {"return"},
   },
   entry = {
      {"http.server"},
      {"assets.http"}, --{"io.print"},
      {"assets", os.getenv("HOME")},
      {"go", "insert_db"},
      {"assets.http_ret"},
      arg[1] == "loop" and {"go", "entry"} or {"return"},
   },
   insert_db = {
      --{"attach.en"},
      {"go", "db"}, },
   db = {
      {"db.sql"},
   },
}

prog.run()
