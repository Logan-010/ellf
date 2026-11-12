val init : ?path:string option -> unit -> Sqlite3.db

val insert_file :
  Sqlite3.db -> string -> string -> string -> int64 option -> unit
val insert_dir :
  Sqlite3.db -> string -> string -> int64
