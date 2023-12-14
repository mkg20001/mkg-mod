{ stdenv
, fetchFromGitHub
, sipcalc
, makeWrapper
, gawk
, iproute2
, gnugrep
, coreutils
}:

stdenv.mkDerivation {
  name = "6in4";

  src = fetchFromGitHub {
    owner = "mkg20001";
    repo = "6in4";
    rev = "2eef73a72bce86bf4c2d5086e277edeebf8a7433";
    hash = "sha256-wGTnmgSGBb1NNJFGqCKuoqawbRWtAQNjrFWLJUc1Xag=";
  };

  /*fetchFromGitHub {
    owner = "sskaje";
    repo = "6in4";
    rev = "f8970864416a96f851d469d83a3cfd87037abe9e";
    hash = "sha256-x4oI7fujJVsJDIXQ3dwf8SJWOYqSN2Ac+wQ8M1OtX2k=";
  };*/

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    sipcalc
    gawk
    iproute2
    gnugrep
  ];

  buildPhase = ''
    sed 's|$(dirname $0)/../etc/config.ini|/etc/6in4.ini|' -i bin/6to4
    sed 's|`which sipcalc`|${sipcalc}/bin/sipcalc|g' -i bin/6to4
    sed 's|sudo |/run/wrappers/bin/sudo |g' -i cgi/*.php
  '';

  installPhase = ''
    mkdir -p $out/cgi-bin
    cp cgi/*.php $out/cgi-bin
    install -D bin/6to4 $out/bin/6to4
    mkdir -p $out/etc
    ln -s /etc/6to4.ini $out/etc/config.ini
    wrapProgram $out/bin/6to4 \
      --prefix PATH : "${gawk}/bin:${iproute2}/bin:${gnugrep}/bin:${coreutils}/bin"
  '';
}
