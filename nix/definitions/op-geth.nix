{
  pkgs,
  src,
  imageBuilder,
  ...
}: let
  op-geth = pkgs.stdenv.mkDerivation {
    name = "op-geth";
    inherit src;

    nativeBuildInputs = with pkgs; [
      go
      gnumake
    ];

    buildPhase = ''
      HOME=$TMPDIR make geth
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp build/bin/geth $out/bin/
    '';
  };
in
  imageBuilder {
    copyToRoot = [
      op-geth
    ];
    config = {
      ExposedPorts = {
        "8545/tcp" = {};
        "8546/tcp" = {};
        "30303/tcp" = {};
        "30303/udp" = {};
      };
    };
  }
