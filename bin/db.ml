exception UnsupportedOS

let home =
  if Sys.unix then Sys.getenv "HOME"
  else if Sys.cygwin || Sys.win32 then Sys.getenv "USERPROFILE"
  else raise UnsupportedOS

let init ?(path = None) () =
(    match path with Some p -> p | None -> Filename.concat home ".ellf.db") |> 
  Sqlite3.db_open
