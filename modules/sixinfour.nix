{ config, pkgs, lib, ... }:

with lib;

let
  type = pkgs.formats.keyValue {};
  cfg = config.services.sixinfour;
in
{
  options = {
    services.sixinfour = {
      enable = mkEnableOption "6in4";

      hostname = mkOption {
        type = types.str;
        description = "Hostname to use";
      };

      settings = mkOption {
        type = type.type;
        description = "Settings for sixinfour";
      };

      auth = mkOption {
        type = with types; attrsOf str;
        description = "Auth";
        default = {};
      };
    };
  };

  config = mkIf (cfg.enable) {
    boot.kernel.sysctl = {
      # forwarding
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
    };

    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      virtualHosts.${cfg.hostname} = {
        root = "${pkgs.sixinfour}/cgi-bin";
        enableACME = true;
        forceSSL = true;
        basicAuth = cfg.auth;
        # locations."/".tryFiles = "$uri @index.html";
        locations."~ \.php$".extraConfig = ''
          fastcgi_pass  unix:${config.services.phpfpm.pools.sixinfour.socket};
          fastcgi_index index.php;
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [
      80 443
    ];

    networking.firewall.allowedUDPPorts = [
      443
    ];

    environment.systemPackages = with pkgs; [
      sixinfour
    ];

    users.users.sixinfour = {
      isSystemUser = true;
      group = "sixinfour";
    };

    users.groups.sixinfour = {};

    services.phpfpm.pools.sixinfour = {
      user = "sixinfour";                                                                                                                                                                                                                           
      settings = {                                                                                                                                                                                                                               
        pm = "dynamic";            
        "listen.owner" = config.services.nginx.user;
        "pm.max_children" = 5;                                                                                                                                                                                                                   
        "pm.start_servers" = 2;                                                                                                                                                                                                                  
        "pm.min_spare_servers" = 1;                                                                                                                                                                                                              
        "pm.max_spare_servers" = 3;                                                                                                                                                                                                              
        "pm.max_requests" = 500;                                                                                                                                                                                                                 
      };                                                                                                                                                                                                                                         
    };

    security.sudo.extraRules = [ {
      users = [ "sixinfour" ];
      commands = [
        { command = "${pkgs.sixinfour}/bin/6to4"; options = [ "NOPASSWD" ]; }
      ];
    } ];

    environment.etc."6in4.ini".source = type.generate "6in4.ini" cfg.settings;

    networking.firewall.extraInputRules = ''
      ip protocol 41 ip daddr ${cfg.settings.BIND_IP} accept
    '';

    networking.firewall.extraForwardRules = ''
      iifname "tun*" ip6 saddr ${cfg.settings.IPV6_NETWORK}/${toString cfg.settings.IPV6_CIDR} oifname "${cfg.settings.INTERFACE}" accept
      iifname "tun*" ip6 saddr ${cfg.settings.IPV6_NETWORK}/${toString cfg.settings.IPV6_CIDR} ip6 daddr ${cfg.settings.IPV6_NETWORK}/${toString cfg.settings.IPV6_CIDR} oifname "tun*" accept
      iifname "${cfg.settings.INTERFACE}" ip6 daddr ${cfg.settings.IPV6_NETWORK}/${toString cfg.settings.IPV6_CIDR} oifname "tun*" accept
    '';

    systemd.services.sixinfour-restore = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "6to4";
      };
      path = with pkgs; [ sixinfour ];
      script = ''
        6to4 restore 0.0.0.0
      '';
    };
  };
}
