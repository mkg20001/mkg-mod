{ config, pkgs, lib, ... }:

with lib;

let
  type = pkgs.formats.keyValue {};
  cfg = config.services.jit6;
  pkg = pkgs.jit6;
in
{
  options = {
    services.jit6 = {
      enable = mkEnableOption "just-in-time ipv6";

      hostname = mkOption {
        type = types.str;
        description = "Hostname to use";
      };

      settings = mkOption {
        type = type.type;
        description = "Settings for jit6";
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
      # "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.default.forwarding" = true;

      # allow IPv6 addrs to directly go out
      "net.ipv6.conf.all.proxy_ndp" = "1";
    };

    networking.firewall.allowedUDPPorts = [ 6464 ];
    networking.firewall.trustedInterfaces = [ "jit6" ];
    networking.firewall.extraForwardRules = ''
      iifname { "jit6", "eth0" } oifname { "jit6", "eth0" } accept
    '';

    users.users.jit6 = {
      isSystemUser = true;
      group = "jit6";
    };

    users.groups.jit6 = {};

    environment.etc."jit6".source = type.generate "jit6" cfg.settings;

    services.phpfpm.pools.jit6 = {
      user = "jit6";
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
      users = [ "jit6" ];
      commands = [
        { command = "${jit6sh}"; options = [ "NOPASSWD" ]; }
      ];
    } ];

    networking.wireguard.interfaces = {
      # "wg0" is the network interface name. You can name the interface arbitrarily.
      jit6 = {
        # Determines the IP address and subnet of the server's end of the tunnel interface.
        ips = [ ];

        # The port that WireGuard listens to. Must be accessible by the client.
        listenPort = 6464;

        #
        # Note: The private key can also be included inline via the privateKey option,
        # but this makes the private key world-readable; thus, using privateKeyFile is
        # recommended.
        privateKeyFile = "/var/wg-priv-jit6";

        peers = [ ];
      };
    };

    services.nginx.virtualHosts.${cfg.hostname} = {
      root = "${pkg.php}";
      enableACME = true;
      forceSSL = true;
      locations."/".extraConfig = "index index.html;";
      locations."~ \.php$" = {
        basicAuth = cfg.auth;

        extraConfig = ''
          fastcgi_pass  unix:${config.services.phpfpm.pools.jit6.socket};
          fastcgi_index index.php;
        '';
      };
    };

    systemd.services.jit6-gc = {
      startAt = "*-*-* 0/1:00:00";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = jit6gc;
        StateDirectory = "jit6";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };

    environment.systemPackages = with pkgs; [ ipcalc ];
  };
}
