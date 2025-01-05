# Build the output html & javascript.
build:
    nix build .#epochSI

# Check everything
check:
    nix flake check

# Use elm-live to get hot reloading.
live: makedist
    elm-live ./fe/Main.elm --hot --dir=./dist -- --output=./dist/Main.js

# Put files in ./dist, for local dev
makedist:
    elm make fe/Main.elm --output dist/Main.js
