{ stdenv
, oils-for-unix
, wireguard-tools
, hexdump
, gnused
, iproute2
, coreutils
}:

stdenv.mkDerivation {
  name = "jit6";
  outputs = [ "sh" "gc" "php" ];

  src = ./src;

  buildPhase = ''
    sed -e "s|@path@|${lib.makeBinPath [ wireguard-tools hexdump gnused iproute2 ]}|g" -i jit6.sh

    sed -e "s|@path@|${lib.makeBinPath [ wireguard-tools coreutils iproute2 ]}|g" -i jit6-gc.ysh
    patchShebangs jit6-gc.ysh
  '';
  installPhase = ''
    cp jit6.sh $sh

    cp jit6-gc.ysh $gc

    mkdir -p $php
    cp jit6.php $php/jit6.php
    cp jit6-client $php/index.html
    sed -e 's|sudo |/run/wrappers/bin/sudo |g' -e "s|@jit6bin@|${jit6sh}|g" -i $php/jit6.php
  '';
}
