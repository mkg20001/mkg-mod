{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mkg.mod.firewall-ips;
in
{
  options = with types; {
    mkg.mod.firewall-ips = {
      enable = mkEnableOption "firewall ip passthru";

      ips = mkOption {
        type = listOf str;
        default = [];
      };
    };
  };

  config = mkIf (cfg.enable) {
    networking.firewall.extraInputRules = (mkIf (config.networking.nftables.enable)
      "ip6 saddr {${concatMapStringsSep "," (ip: "${ip}/128") (cfg.ips)}} accept"
    );
    networking.firewall.extraCommands = (mkIf (!config.networking.nftables.enable)
      (concatMapStringsSep "\n" (ip: "ip6tables -A INPUT -s ${ip} -j ACCEPT") (cfg.ips))
    );
  ];
 };
}
