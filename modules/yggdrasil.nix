# Enable yggdrasil
# docref: <nixpkgs/nixos/modules/services/networking/yggdrasil.nix>

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mkg.mod.yggdrasil;
in
{
  options = with types; {
    mkg.mod.yggdrasil = {
      enable = mkEnableOption "mkg's yggdrasil";

      port = mkOption {
        type = int;
        description = "A random port";
      };

      peers = mkOption {
        type = listOf str;
        default = [];
      };
    };
  };

  config = mkIf (cfg.enable) {
    # Enable the yggdrasil daemon.
    services.yggdrasil = {
      enable = true;

      persistentKeys = true;
      openMulticastPort = true;
      denyDhcpcdInterfaces = [ "ygg*" ];

      settings = {
        Peers = cfg.peers;

        IfName = "ygg0";

        MulticastInterfaces = [
          {
            Regex = ".*";
            Beacon = true;
            Listen = true;
            Port = cfg.port + 1;
            Priority = 0;
          }
        ];

        Listen = [
          "tcp://[::]:${toString cfg.port}"
          "tls://[::]:${toString (cfg.port + 2)}"
        ];
      };
    };

    # yggdrasil is kinda important as we sometimes deploy over it, so keep it always on
    systemd.services.yggdrasil.restartIfChanged = false;

    networking.firewall.allowedTCPPorts = [
      cfg.port
      (cfg.port + 1)
      (cfg.port + 2)
    ];
 };
}
