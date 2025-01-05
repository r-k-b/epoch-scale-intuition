{ compiledElmApp, minimalElmSrc, pkgs, sourceInfo, stdenv }:
stdenv.mkDerivation {
  name = "epoch-scale-intuition";
  src = minimalElmSrc;
  # build-time-only dependencies
  nativeBuildDeps = with pkgs; [ ];
  # runtime dependencies
  buildDeps = [ ];
  buildPhase = ''
    patchShebangs *.sh
  '';
  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
    cp ${compiledElmApp}/*.js $out/
  '';
}
