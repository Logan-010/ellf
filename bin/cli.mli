type cli = {
  help : bool;
  version : bool;
  db : string option;
  index : bool;
  filter : string option;
  files_only: bool;
  dirs_only: bool;
  all : bool;
  limit : int option;
  args : string list;
}

val usage : string
val version : string
val spec : (string * Arg.spec * string) list
val parse : unit -> cli
