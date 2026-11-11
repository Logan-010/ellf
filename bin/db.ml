let exec db sql =
  match Sqlite3.exec db sql with
  | Sqlite3.Rc.OK -> ()
  | rc ->
      failwith
        (Printf.sprintf "SQLite error: %s (%s)" (Sqlite3.Rc.to_string rc)
           (Sqlite3.errmsg db))

let migration_1 =
  {|CREATE TABLE IF NOT EXISTS directories (
      id INTEGER NOT NULL PRIMARY KEY,
      path TEXT NOT NULL,
      hash BLOB NOT NULL
    );
    CREATE TABLE IF NOT EXISTS files (
      id INTEGER NOT NULL PRIMARY KEY,
      path TEXT NOT NULL,
      hash BLOB NOT NULL,
      file_type TEXT NOT NULL,
      directory_id INTEGER NOT NULL,
      FOREIGN KEY (directory_id) REFERENCES directories(id)
      ON DELETE CASCADE
    );
    PRAGMA user_version = 1;|}

let migrate db =
  let version = ref None in

  let cb row _headers =
    match row.(0) with
    | Some value -> version := Some (int_of_string value)
    | None -> failwith "Invalid user_version"
  in

  (match Sqlite3.exec ~cb db "PRAGMA user_version;" with
  | Sqlite3.Rc.OK -> ()
  | rc ->
      failwith
        (Printf.sprintf "SQLite error: %s (%s)" (Sqlite3.Rc.to_string rc)
           (Sqlite3.errmsg db)));

  let version =
    match !version with
    | Some v -> v
    | None -> failwith "Could not read database version"
  in

  exec db "BEGIN IMMEDIATE;";
  try
    if version < 1 then exec db migration_1;
    exec db "COMMIT;"
  with exn ->
    exec db "ROLLBACK;";
    raise exn

exception UnsupportedOS

let home =
  if Sys.unix then Sys.getenv "HOME"
  else if Sys.cygwin || Sys.win32 then Sys.getenv "USERPROFILE"
  else raise UnsupportedOS

let init ?(path = None) () =
  let db =
    (match path with Some p -> p | None -> Filename.concat home ".ellf.db")
    |> Sqlite3.db_open
  in

  try
    exec db "PRAGMA foreign_keys = ON;";
    migrate db;
    db
  with exn ->
    ignore (Sqlite3.db_close db);
    raise exn
