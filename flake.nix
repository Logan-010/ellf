{
  description = "Ellf Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        ocamlPackages = pkgs.ocamlPackages;
      in
      {
        packages.default = ocamlPackages.buildDunePackage {
          pname = "ellf";
          version = "0.1.0";
          meta.mainProgram = "lf";

          src = ./.;

          duneVersion = "3";

          # Opam packages needed
          propagatedBuildInputs = [
            ocamlPackages.digestif
            ocamlPackages.sqlite3
          ];

          # Libraries needed at compile-time
          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          # Libraries needed at runtime
          buildInputs = [
          ];
        };

        devShells.default = pkgs.mkShell {
          packages = [
            # Development
            ocamlPackages.ocaml
            ocamlPackages.dune_3
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
            ocamlPackages.utop
            ocamlPackages.findlib
            ocamlPackages.ocaml-print-intf

            # Deps
            ocamlPackages.digestif
            ocamlPackages.sqlite3
          ];
        };
      }
    );
}
