let green = "\x1b[32m"
let red = "\x1b[31m"
let italic = "\x1b[3m"
let bold = "\x1b[1m"
let reset = "\x1b[0m"

let print_filename color path =
  if color then print_endline @@ bold ^ green ^ path ^ reset
  else print_endline path

let print_match color matches line =
  if color then
    print_endline
    @@ List.fold_left
         (fun o m -> String.replace_all ~sub:m ~by:(italic ^ red ^ m ^ reset) o)
         line matches
  else print_endline line

let display color matches entries =
  List.map
    (fun (e : Search.entry) ->
      print_filename color e.path;
      List.iter (fun m -> print_match color matches m) e.file_content_matches)
    entries
  |> ignore
