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
  nativeBuildInputs = with pkgs; [
    unstable.terraform
  ];

  shellHook = ''
    if [ -f .env ]; then
      export $(grep -v '^#' .env | xargs)
    fi
  '';
}
