(lang dune 3.23)

(name ellf)

(generate_opam_files true)

(source
 (github Logan-010/ellf))

(authors "Logan Briesemeister")

(maintainers "Logan Briesemeister")

(license LICENSE)

(package
 (name ellf)
 (synopsis "Fast file finding")
 (description "Search through a smart index of your local files")
 (depends ocaml digestif sqlite3)
 (tags
  (sqlite search index)))
