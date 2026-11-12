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

let contains query text =
  try
    ignore (Str.search_forward query text 0);
    true
  with Not_found -> false

let search db (cli : Cli.cli) =
  let queries = List.map Str.regexp_string cli.args in
  let matches text = List.exists (fun query -> contains query text) queries in
  let results =
    Db.list_entries db [] true
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
    |> List.filter_map (fun (_, path, file_type) ->
        let name = Filename.basename path in
        let dir = Filename.dirname path in

        let file_content_matches =
          match file_type with
          | Some t when Array.mem t Mime_text_types.types ->
              (try
                 let f = open_in path in
                 Fun.protect
                   ~finally:(fun () -> close_in_noerr f)
                   (fun () ->
                     let rec collect acc =
                       match input_line f with
                       | line ->
                           collect (if matches line then line :: acc else acc)
                       | exception End_of_file -> List.rev acc
                     in
                     collect [])
               with Sys_error _ -> [])
          | _ -> []
        in

        let matches_query query =
          contains query path
          || List.exists (contains query) file_content_matches
        in
        let matches_queries =
          if cli.all then List.for_all matches_query queries
          else List.exists matches_query queries
        in
        if matches_queries then
          Some
            {
              path;
              file_type;
              file_content_matches;
              name_match = matches name;
              path_match = matches dir;
            }
        else None)
    |> List.map (fun entry -> (entry, weigh_entry entry))
    |> List.sort (fun (_, a) (_, b) -> Int.compare b a)
    |> List.filter (fun (_, score) -> score > 0)
    |> List.map (fun (e, _) -> e)
  in
  match cli.limit with
  | Some n -> List.filteri (fun i _ -> i < n) results
  | None -> results
