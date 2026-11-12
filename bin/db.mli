val init : ?path:string option -> unit -> Sqlite3.db
val with_transaction : Sqlite3.db -> (unit -> 'a) -> 'a

val find_file : Sqlite3.db -> string -> string -> int64 option
val find_dir : Sqlite3.db -> string -> string -> int64 option

val list_entries :
  Sqlite3.db -> string list -> bool -> (bool * string * string option) list

val insert_file :
  Sqlite3.db -> string -> string -> string -> int64 option -> unit

val insert_dir : Sqlite3.db -> string -> string -> int64
