type cli = {
  help : bool;
  version : bool;
  db : string option;
  index : bool;
  filter : string option;
  all : bool;
  limit: int option;
  args : string list;
}

let usage = "lf [-verbose] <path> [<path>] ..."
let version = "lf v0.1.0"
let help_ref = ref false
let version_ref = ref false
let db_ref = ref None
let index_ref = ref false
let filter_ref = ref None
let all_ref = ref false
let limit_ref = ref None
let args_ref = ref []

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
    ("--filter", Arg.String (fun s -> filter_ref := Some s), "Set filter type");
    ("-f", Arg.String (fun s -> filter_ref := Some s), "Short for --filter");
    ("--all", Arg.Set help_ref, "Search matches all queries instead of any");
    ("-a", Arg.Set help_ref, "Short for --all");
    ("--limit", Arg.Int (fun i -> limit_ref := Some i), "Limit results returned");
    ("-l", Arg.Int (fun i -> limit_ref := Some i), "Short for --limit")
  ]

let parse () =
  help_ref := false;
  version_ref := false;
  db_ref := None;
  index_ref := false;
  filter_ref := None;
  all_ref := false;
  limit_ref := None;
  args_ref := [];

  Arg.parse spec (fun a -> args_ref := !args_ref @ [ a ]) usage;

  {
    help = !help_ref;
    version = !version_ref;
    db = !db_ref;
    index = !index_ref;
    filter = !filter_ref;
    all = !all_ref;
    limit = !limit_ref;
    args = !args_ref;
  }
