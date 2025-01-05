# This file was generated by `elm2nix init > default.nix`
#
# the default output of `elm2nix init` doesn't seem to work with Flakes; I've
# manually replaced the next two lines:
# { nixpkgs ? <nixpkgs>, config ? { } }:
# with (import nixpkgs config);
{ elmPackages, lib, pkgs, minimalElmSrc, nodePackages, stdenv }:
let
  mkDerivation = { srcs ? ./elm/elm-srcs-main.nix, src, name, srcdir ? "../src"
    , targets ? [ ], registryDat ? ./elm/registry.dat, outputJavaScript ? false
    }:
    stdenv.mkDerivation {
      inherit name src;

      nativeBuildInputs = [ elmPackages.elm ]
        ++ lib.optional outputJavaScript nodePackages.uglify-js;

      installPhase = let
        elmfile = module:
          "${srcdir}/${builtins.replaceStrings [ "." ] [ "/" ] module}.elm";
        extension = if outputJavaScript then "js" else "html";
      in ''
        ${pkgs.makeDotElmDirectoryCmd { elmJson = ../elm.json; }}
        mkdir -p $out/share/doc
        ${lib.concatStrings (map (module: ''
          echo "compiling ${elmfile module}"
          elm make ${
            elmfile module
          } --output $out/${module}.${extension} --docs $out/share/doc/${module}.json
          ${lib.optionalString outputJavaScript ''
            echo "minifying ${elmfile module}"
            uglifyjs $out/${module}.${extension} --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
                | uglifyjs --mangle --output $out/${module}.min.${extension}
          ''}
        '') targets)}
      '';
    };
in mkDerivation {
  name = "tulars-mkElmDerivation-0.1.0";
  srcs = ./elm/elm-srcs-main.nix;
  src = minimalElmSrc;
  targets = [ "Main" ];
  srcdir = "./fe";
  outputJavaScript = true;
}
