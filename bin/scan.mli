type file_meta =
  | Dir of string * Digestif.BLAKE3.t * file_meta list
  | File of string * Digestif.BLAKE3.t * string

val index : string -> file_meta 
