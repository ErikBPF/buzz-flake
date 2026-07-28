check:
    bash tests/contracts.sh
    nix flake check

build:
    nix build .#buzz
