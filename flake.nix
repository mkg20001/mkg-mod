{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    overlays.default = import ./pkgs/overlay.nix;

    nixosModules = {
      yggdrasil = import ./modules/yggdrasil.nix;
      firewall-ips = import ./modules/firewall-ips.nix;
      server-base = import ./modules/server-base.nix;
      sixinfour = import ./modules/sixinfour.nix;
    };

  };
}
