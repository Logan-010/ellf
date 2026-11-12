type cli = {
  help : bool;
  version : bool;
  db : string option;
  index : bool;
  args : string list;
}

let usage = "lf [-verbose] <path> [<path>] ..."
let version = "lf v0.1.0"
let help_ref = ref false
let version_ref = ref false
let index_ref = ref false
let args_ref = ref []
let db_ref = ref None

let spec =
  [
    ("--help", Arg.Set help_ref, "Show this menu");
    ("-h", Arg.Set help_ref, "Short for --help");
    ("--version", Arg.Set version_ref, "Show the version");
    ("-v", Arg.Set version_ref, "Short for --version");
    ("--index", Arg.Set index_ref, "Index dindex_refectories");
    ("-i", Arg.Set index_ref, "Short for --index");
    ( "--database",
      Arg.String (fun s -> db_ref := Some s),
      "Set path to the database" );
    ("-d", Arg.String (fun s -> db_ref := Some s), "Short for --database");
  ]

let parse () =
  help_ref := false;
  version_ref := false;
  index_ref := false;
  args_ref := [];

  Arg.parse spec (fun a -> args_ref := !args_ref @ [ a ]) usage;

  {
    help = !help_ref;
    version = !version_ref;
    db = !db_ref;
    index = !index_ref;
    args = !args_ref;
  }
