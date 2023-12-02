{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    nixosModules = {
      yggdrasil = import ./modules/yggdrasil.nix;
      firewall-ips = import ./modules/firewall-ips.nix;
      server-base = import ./modules/server-base.nix;
    };

  };
}
