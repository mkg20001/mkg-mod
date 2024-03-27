#!/bin/sh

export PATH="@path@"

. /etc/jit6

PREF="$IPV6_64_PREFIX"
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
Endpoint = $INCOMING_IP:6464

# VPN Subnet and IPv6 Tunnel
AllowedIPs = ::/0
"
