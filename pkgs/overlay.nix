final: prev: with builtins; let
  byName = ./by-name;
  pkgs = mapAttrs (pkg: _: prev.callPackage "${byName}/${pkg}/package.nix" {}) (readDir byName);
in pkgs
