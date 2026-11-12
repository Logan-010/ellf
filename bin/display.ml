let display color entries =
  List.map
    (fun (e : Search.entry) ->
      print_endline e.path;
      List.iter (fun m -> print_endline m) e.file_content_matches)
    entries |> ignore
