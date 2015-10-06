default: c_header.lua

c_header.h: /usr/include/sqlite3.h
	gcc -E /usr/include/sqlite3.h  |grep -v '# ' |grep -v __gnuc_ > c_header.h

c_header.lua: c_header.h c_header.sh
	sh c_header.sh > c_header.lua
