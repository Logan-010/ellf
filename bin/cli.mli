type cli = { help : bool; version : bool; db: string option; index : bool; args : string list }

val usage : string
val version : string
val spec : (string * Arg.spec * string) list
val parse : unit -> cli
