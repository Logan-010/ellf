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

let encode entries =
  `List
    (List.map
       (fun (e : Search.entry) ->
         `Assoc
           [
             ("path", `String e.path);
             ( "matches",
               `List (List.map (fun m -> `String m) e.file_content_matches) );
           ])
       entries)

let display (cli : Cli.cli) entries =
  if cli.json then entries |> encode |> Yojson.to_string |> print_endline
  else
    List.fold_left
      (fun _ (e : Search.entry) ->
        print_filename (not cli.colorless) e.path;
        List.fold_left
          (fun _ m -> print_match (not cli.colorless) cli.args m)
          () e.file_content_matches)
      () entries
