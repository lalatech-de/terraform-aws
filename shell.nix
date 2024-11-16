{ pkgs ? import <nixpkgs> {} }:
let
  unstable = import (fetchTarball "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz") {
    config = {
      allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
        "terraform"
      ];
    };
  };
in
pkgs.mkShell {
  nativeBuildInputs = [
    unstable.terraform
    unstable.awscli2
  ];

  shellHook = ''
    if [ -f .env ]; then
      export $(grep -v '^#' .env | xargs)
    fi
  '';
}