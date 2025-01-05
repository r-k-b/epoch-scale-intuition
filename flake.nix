{
  description =
    "Get a sense for the calendar parts behind a given Unix Epoch Timestamp";

  inputs = {
    flake-utils = { url = "github:numtide/flake-utils"; };
    mkElmDerivation = {
      url = "github:r-k-b/mkElmDerivation?ref=support-elm-review";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, flake-utils, mkElmDerivation, nixpkgs }:
    let supportedSystems = with flake-utils.lib.system; [ x86_64-linux ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ mkElmDerivation.overlays.makeDotElmDirectoryCmd ];
        };
        inherit (pkgs) lib stdenv callPackage;
        inherit (lib) fileset hasInfix hasSuffix;

        toSource = fsets:
          fileset.toSource {
            root = ./.;
            fileset = fileset.unions fsets;
          };

        # The build cache will be invalidated if any of the files within change.
        # So, exclude files from here unless they're necessary for `elm make` et al.
        minimalElmSrc = toSource [
          (fileset.fileFilter (file: file.hasExt "elm") ./fe)
          ./dist
          ./elm.json
        ];

        compiledElmApp =
          callPackage ./nix/default.nix { inherit minimalElmSrc; };

        built = callPackage ./nix/built.nix {
          inherit compiledElmApp minimalElmSrc;
          sourceInfo = self.sourceInfo;
        };

        peekSrc = name: src:
          stdenv.mkDerivation {
            src = src;
            name = "peekSource-${name}";
            buildPhase = "mkdir -p $out";
            installPhase = "cp -r ./* $out";
          };

      in {
        checks = { inherit built compiledElmApp; };
        packages = {
          inherit built compiledElmApp;
          default = built;
          minimalElmSrc = peekSrc "minimal-elm" minimalElmSrc;
        };
        devShells.default = pkgs.mkShell {
          name = "epochscaleintuition-dev-shell";

          buildInputs = with pkgs;
            [
              just
              nixfmt-classic
              nushell # for less inscrutable scripting than bash
            ] ++ (with pkgs.elmPackages; [ elm elm-format elm-live elm-test ]);

          shellHook = ''
            printf 'just: '
            just --list
          '';
        };

      });
}
