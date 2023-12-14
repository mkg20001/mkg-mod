{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mkg.mod.server-base;
in
{
  options = with types; {
    mkg.mod.server-base = {
      enable = mkEnableOption "server base configuration";

      autoUpgrade = mkEnableOption "automatically upgrade using nixpkgs channels";
    };
  };

  config = mkIf (cfg.enable) {
    # htop
    programs.htop = {
      enable = true;
      settings = {
        hide_userland_threads = true;
      };
    };

    # convinience
    security.sudo.wheelNeedsPassword = false;

    # testing future stuff
    networking.useNetworkd = true;
    boot.initrd.systemd.enable = true;
    networking.nftables.enable = true;
    nix.settings.experimental-features = "nix-command flakes";

    # security
    services.openssh = {
      enable = true;
      # require public key authentication for better security
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    system.autoUpgrade = mkIf (cfg.autoUpgrade) {
      enable = true;
      allowReboot = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };
}
