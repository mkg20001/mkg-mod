#!/bin/sh

export PATH="@path@"

PREF="2a01:7e01:e003:2864"
PREFSIZE="64";
SUF=$(hexdump -vn8 -e'2/1 "%1x" 1 ":"' /dev/urandom | sed 's|:$||')

IP="$PREF:$SUF/128"

PRIVKEY=$(wg genkey)
PUBKEY=$(echo "$PRIVKEY" | wg pubkey)

wg set jit6 peer "$PUBKEY" allowed-ips "$IP"
ip route replace "$IP" dev jit6 table main

echo "
[Interface]
# The address your computer will use on the VPN
Address = $IP
PrivateKey = $PRIVKEY
DNS = 2606:4700:4700::1111, 2606:4700:4700::1001, 1.1.1.1, 1.0.0.1

[Peer]
# VPN server's wireguard public key
PublicKey = DS8+lOzNk9IAyuQ9W0ABENnwowSo/gluaeuBTwPmO20=

# Public IP address of your VPN server
Endpoint = 172.104.147.111:6464

# VPN Subnet and IPv6 Tunnel
AllowedIPs = ::/0
"
