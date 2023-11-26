{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    nixosModules = {
      yggdrasil = import ./modules/yggdrasil.nix;
    };

  };
}
