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

let feed_length ctx n =
  let buf = Bytes.create 8 in
  let n = Int64.of_int n in

  for i = 0 to 7 do
    let byte = Int64.(to_int (logand (shift_right_logical n (8 * i)) 0xffL)) in
    Bytes.set buf (7 - i) (Char.chr byte)
  done;

  Hash.feed_bytes ctx buf

let feed_name ctx name =
  ctx |> fun ctx ->
  feed_length ctx (String.length name) |> fun ctx -> Hash.feed_string ctx name

let entry_hash = function Dir (_, h, _) | File (_, h, _) -> h

let hash_directory entries =
  let ctx = Hash.feed_string Hash.empty "D\000" in

  let ctx =
    Array.fold_left
      (fun ctx entry ->
        let name, tag =
          match entry with
          | Dir (path, _, _) -> (Filename.basename path, "D")
          | File (path, _, _) -> (Filename.basename path, "F")
        in

        let ctx = Hash.feed_string ctx tag in
        let ctx = feed_name ctx name in

        Hash.feed_string ctx (Hash.to_raw_string (entry_hash entry)))
      ctx entries
  in

  Hash.get ctx

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

let index path =
  let num_domains = max 1 (Domain.recommended_domain_count ()) in

  let pool = Task.setup_pool ~num_domains:(num_domains - 1) () in

  Fun.protect
    ~finally:(fun () -> Task.teardown_pool pool)
    (fun () -> Task.run pool (fun () -> index_in_pool pool path))
