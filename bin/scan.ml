let buffer_size = 1024 * 1024

let sum ic =
  let buf = Bytes.create buffer_size in
  let rec go ctx =
    match input ic buf 0 buffer_size with
    | 0 -> Digestif.BLAKE3.get ctx
    | len ->
        let ctx = Digestif.BLAKE3.feed_bytes ctx ~off:0 ~len buf in
        go ctx
    | exception End_of_file -> Digestif.BLAKE3.get ctx
  in
  go Digestif.BLAKE3.empty
