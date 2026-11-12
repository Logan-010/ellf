module Hash = Digestif.BLAKE3
module Task = Domainslib.Task

let buffer_size = 1024 * 1024

type file_meta =
  | Dir of string * Hash.t * file_meta list
  | File of string * Hash.t * string

let sum ic =
  let buf = Bytes.create buffer_size in

  let rec go ctx =
    match input ic buf 0 buffer_size with
    | 0 -> Hash.get ctx
    | len -> go (Hash.feed_bytes ctx ~off:0 ~len buf)
  in

  go Hash.empty

let hash_file path =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in ic) (fun () -> sum ic)

let entry_hash = function Dir (_, h, _) | File (_, h, _) -> h
let entry_name = function Dir (n, _, _) | File (n, _, _) -> n

let hash_directory entries =
  Array.fold_left
    (fun ctx entry ->
      let ctx = Hash.feed_string ctx (Hash.to_raw_string (entry_hash entry)) in
      let ctx = Hash.feed_string ctx (Filename.basename (entry_name entry)) in
      Hash.feed_string ctx "\000")
    Hash.empty entries
  |> Hash.get

let rec index_in_pool pool path =
  if Sys.is_directory path then (
    let names = Sys.readdir path in
    Array.sort String.compare names;

    let tasks =
      Array.map
        (fun name ->
          let child = Filename.concat path name in
          Task.async pool (fun () -> index_in_pool pool child))
        names
    in

    let entries = Array.map (Task.await pool) tasks in

    let hash = hash_directory entries in
    Dir (path, hash, Array.to_list entries))
  else if Sys.file_exists path then
    let hash = hash_file path in
    let mime = Magic_mime.lookup path in
    File (path, hash, mime)
  else failwith ("Path does not exist: " ^ path)

let absolute_path path =
  let path =
    if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path
    else path
  in
  let rec split path parts =
    let parent = Filename.dirname path in
    if parent = path then (path, parts)
    else split parent (Filename.basename path :: parts)
  in
  let root, parts = split path [] in
  let parts =
    List.fold_left
      (fun parts -> function
        | "." -> parts
        | ".." -> (match parts with [] -> [] | _ :: rest -> rest)
        | name -> name :: parts)
      [] parts
  in
  List.fold_left Filename.concat root (List.rev parts)

let index path =
  let path = absolute_path path in
  let num_domains = max 1 (Domain.recommended_domain_count ()) in

  let pool = Task.setup_pool ~num_domains:(num_domains - 1) () in

  Fun.protect
    ~finally:(fun () -> Task.teardown_pool pool)
    (fun () -> Task.run pool (fun () -> index_in_pool pool path))

let place db meta =
  let rec place' db meta pid =
    match meta with
    | File (p, h, t) ->
        let hash = Hash.to_raw_string h in
        (match Db.find_file db p hash with
        | Some _ -> ()
        | None -> Db.insert_file db p hash t pid)
    | Dir (p, h, c) ->
        let hash = Hash.to_raw_string h in
        let id =
          match Db.find_dir db p hash with
          | Some id -> id
          | None -> Db.insert_dir db p hash
        in
        List.iter (fun e -> place' db e (Some id)) c
  in

  Db.with_transaction db (fun () -> place' db meta None)
