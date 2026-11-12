type cli = {
  help : bool;
  version : bool;
  db : string option;
  index : bool;
  filter : string option;
  files_only : bool;
  dirs_only : bool;
  all : bool;
  limit : int option;
  args : string list;
  colorless : bool;
}

let usage = "Usage: lf [OPTIONS] [QUERY]...\n\
            \n\
            Search through a smart index of your local files"
let version = "lf v0.1.0"
let help_ref = ref false
let version_ref = ref false
let db_ref = ref None
let index_ref = ref false
let filter_ref = ref None
let files_only_ref = ref false
let dirs_only_ref = ref false
let all_ref = ref false
let limit_ref = ref None
let args_ref = ref []
let colorless_ref = ref false

let spec =
  [
    ("--help", Arg.Set help_ref, "Show this menu");
    ("-h", Arg.Set help_ref, "Short for --help");
    ("--version", Arg.Set version_ref, "Show the version");
    ("-v", Arg.Set version_ref, "Short for --version");
    ("--index", Arg.Set index_ref, "Index directories");
    ("-i", Arg.Set index_ref, "Short for --index");
    ( "--database",
      Arg.String (fun s -> db_ref := Some s),
      "Set path to the database" );
    ("-d", Arg.String (fun s -> db_ref := Some s), "Short for --database");
    ("--filter", Arg.String (fun s -> filter_ref := Some s), "Set filter type");
    ("-f", Arg.String (fun s -> filter_ref := Some s), "Short for --filter");
    ("--files", Arg.Set files_only_ref, "Search for only files");
    ("-F", Arg.Set files_only_ref, "Short for --files");
    ("--dirs", Arg.Set dirs_only_ref, "Search for only dirs");
    ("-D", Arg.Set dirs_only_ref, "Short for --dirs");
    ("--all", Arg.Set all_ref, "Search matches all queries instead of any");
    ("-a", Arg.Set all_ref, "Short for --all");
    ("--limit", Arg.Int (fun i -> limit_ref := Some i), "Limit results returned");
    ("-l", Arg.Int (fun i -> limit_ref := Some i), "Short for --limit");
    ("--colorless", Arg.Set colorless_ref, "No color when searching for entries");
    ("-C", Arg.Set colorless_ref, "No color when searching for entries");
  ]

let parse () =
  help_ref := false;
  version_ref := false;
  db_ref := None;
  index_ref := false;
  filter_ref := None;
  all_ref := false;
  files_only_ref := false;
  dirs_only_ref := false;
  limit_ref := None;
  args_ref := [];
  colorless_ref := false;

  Arg.parse spec (fun a -> args_ref := !args_ref @ [ a ]) usage;

  {
    help = !help_ref;
    version = !version_ref;
    db = !db_ref;
    index = !index_ref;
    filter = !filter_ref;
    all = !all_ref;
    files_only = !files_only_ref;
    dirs_only = !dirs_only_ref;
    limit = !limit_ref;
    args = !args_ref;
    colorless = !colorless_ref
  }
