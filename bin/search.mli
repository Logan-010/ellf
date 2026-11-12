type entry = {
  path : string;
  file_type : string option;
  file_content_matches : string list;
  name_match : bool;
  path_match : bool;
}

val search : Sqlite3.db -> Cli.cli -> entry list
