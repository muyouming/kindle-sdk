## Sqlite
Version 3.26.0
```sh
../configure --enable-fts4 --enable-fts5 --enable-json1 --enable-rtree --disable-load-extension --enable-threadsafe
make sqlite3.h
make sqlite3ext.h
make sqlite3.pc
```