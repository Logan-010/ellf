let name_weight = 3
let path_weight = 4
let content_weight = 3

type entry = {
  path : string;
  file_type : string option;
  file_content_matches : string list;
  name_match : bool;
  path_match : bool;
}

let weigh_entry entry =
  (if entry.name_match then name_weight else 0)
  + (if entry.path_match then path_weight else 0)
  + ((entry.file_content_matches |> List.length) * content_weight)

let search db (cli : Cli.cli) =
  let results =
    Db.list_entries db cli.args cli.all
    |> List.filter (fun (is_file, _, file_type) ->
        let matches_type =
          if cli.dirs_only then not is_file
          else if cli.files_only then is_file
          else true
        in
        let matches_filter =
          match cli.filter with
          | Some f -> Option.exists (( = ) f) file_type
          | None -> true
        in
        matches_type && matches_filter)
    |> List.map (fun (_, path, file_type) ->
        let name = Filename.basename path in
        let dir = Filename.dirname path in

        let file_content_matches =
          match file_type with
          | Some t when Array.mem t Mime_text_types.types ->
              let f = open_in path in
              Fun.protect
                ~finally:(fun () -> close_in f)
                (fun () ->
                  let rec collect acc =
                    match input_line f with
                    | line ->
                        let matches =
                          List.exists
                            (fun s ->
                              try
                                ignore
                                  (Str.search_forward (Str.regexp_string s) line
                                     0);
                                true
                              with Not_found -> false)
                            cli.args
                        in
                        collect (if matches then line :: acc else acc)
                    | exception End_of_file -> List.rev acc
                  in
                  collect [])
          | _ -> []
        in

        {
          path;
          file_type;
          file_content_matches;
          name_match = List.exists (( = ) name) cli.args;
          path_match =
            List.exists
              (fun s ->
                try
                  ignore (Str.search_forward (Str.regexp_string s) dir 0);
                  true
                with Not_found -> false)
              cli.args;
        })
    |> List.map (fun entry -> (entry, weigh_entry entry))
    |> List.sort (fun (_, a) (_, b) -> Int.compare b a)
    |> List.filter (fun (_, score) -> score > 0)
    |> List.map (fun (e, _) -> e)
  in
  match cli.limit with
  | Some n -> List.filteri (fun i _ -> i < n) results
  | None -> results
