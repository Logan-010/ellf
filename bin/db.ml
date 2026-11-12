let rc_to_err db = function
  | Sqlite3.Rc.OK -> ()
  | rc ->
      failwith
        (Printf.sprintf "SQLite error: %s (%s)" (Sqlite3.Rc.to_string rc)
           (Sqlite3.errmsg db))

let exec db sql = Sqlite3.exec db sql |> rc_to_err db

let with_transaction db f =
  exec db "BEGIN IMMEDIATE;";
  try
    let result = f () in
    exec db "COMMIT;";
    result
  with exn ->
    exec db "ROLLBACK;";
    raise exn

let migration_1 =
  {|CREATE TABLE IF NOT EXISTS directories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      hash BLOB NOT NULL
    );
    CREATE TABLE IF NOT EXISTS files (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      hash BLOB NOT NULL,
      file_type TEXT NOT NULL,
      directory_id INTEGER,
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

let find_entry db sql path hash =
  let stmt = Sqlite3.prepare db sql in
  Fun.protect
    ~finally:(fun () -> ignore (Sqlite3.finalize stmt))
    (fun () ->
      Sqlite3.bind_text stmt 1 path |> rc_to_err db;
      Sqlite3.bind_blob stmt 2 hash |> rc_to_err db;
      match Sqlite3.step stmt with
      | Sqlite3.Rc.ROW -> Some (Sqlite3.column_int64 stmt 0)
      | Sqlite3.Rc.DONE -> None
      | rc ->
          rc_to_err db rc;
          None)

let find_file db path hash =
  find_entry db "SELECT id FROM files WHERE path = ? AND hash = ? LIMIT 1"
    path hash

let find_dir db path hash =
  find_entry db "SELECT id FROM directories WHERE path = ? AND hash = ? LIMIT 1"
    path hash

let list_entries db names all =
  let matches =
    match names with
    | [] -> if all then "1" else "0"
    | _ ->
        names
        |> List.map (fun _ -> "instr(path, ?) > 0")
        |> String.concat (if all then " AND " else " OR ")
  in
  let sql =
    "SELECT is_file, path, file_type FROM (SELECT 1 AS is_file, path, file_type FROM files UNION ALL \
     SELECT 0 AS is_file, path, NULL AS file_type FROM directories) WHERE ("
    ^ matches ^ ")"
  in
  let stmt = Sqlite3.prepare db sql in
  Fun.protect
    ~finally:(fun () -> ignore (Sqlite3.finalize stmt))
    (fun () ->
      List.iteri
        (fun i name -> Sqlite3.bind_text stmt (i + 1) name |> rc_to_err db)
        names;
      let rec collect entries =
        match Sqlite3.step stmt with
        | Sqlite3.Rc.ROW ->
            let is_file = Sqlite3.column_int stmt 0 = 1 in
            let path = Sqlite3.column_text stmt 1 in
            let file_type =
              if is_file then Some (Sqlite3.column_text stmt 2) else None
            in
            collect ((is_file, path, file_type) :: entries)
        | Sqlite3.Rc.DONE -> List.rev entries
        | rc ->
            rc_to_err db rc;
            List.rev entries
      in
      collect [])

let insert_file db path hash file_type dir =
  let stmt =
    Sqlite3.prepare db
      "INSERT INTO files (path, hash, file_type, directory_id) VALUES (?, ?, \
       ?, ?)"
  in
  Fun.protect
    ~finally:(fun () -> ignore (Sqlite3.finalize stmt))
    (fun () ->
      Sqlite3.bind_text stmt 1 path |> rc_to_err db;
      Sqlite3.bind_blob stmt 2 hash |> rc_to_err db;
      Sqlite3.bind_text stmt 3 file_type |> rc_to_err db;
      (match dir with
        | Some id -> Sqlite3.bind_int64 stmt 4 id
        | None -> Sqlite3.bind stmt 4 Sqlite3.Data.NULL)
      |> rc_to_err db;
      match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> ()
      | rc -> rc_to_err db rc)

let insert_dir db path hash =
  let stmt =
    Sqlite3.prepare db "INSERT INTO directories (path, hash) VALUES (?, ?)"
  in
  Fun.protect
    ~finally:(fun () -> ignore (Sqlite3.finalize stmt))
    (fun () ->
      Sqlite3.bind_text stmt 1 path |> rc_to_err db;
      Sqlite3.bind_blob stmt 2 hash |> rc_to_err db;
      (match Sqlite3.step stmt with
      | Sqlite3.Rc.DONE -> ()
      | rc -> rc_to_err db rc);
      Sqlite3.last_insert_rowid db)
