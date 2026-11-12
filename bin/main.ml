let cli = Cli.parse ()

let () =
  if cli.help then Arg.usage Cli.spec Cli.usage
  else if cli.version then (
    output_string stderr Cli.version;
    output_char stderr '\n')
  else
    let db = Db.init ~path:cli.db () in
    ignore db;

    if cli.index then
      cli.args |> List.map Scan.index |> List.map (Scan.place db) |> ignore
    else
      cli.args |> Search.search db cli.filter cli.all |> ignore 
