{
  description =
    "Get a sense for the calendar parts behind a given Unix Epoch Timestamp";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
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

    };
}
