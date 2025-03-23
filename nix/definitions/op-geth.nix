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
    ];

    buildPhase = ''
      # set HOME to a valid directory for golangci-lint
      HOME=$TMPDIR ${pkgs.gnumake}/bin/make geth
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
      Entrypoint = ["/bin/op-reth"];
      ExposedPorts = {
        "8545/tcp" = {};
        "8546/tcp" = {};
        "30303/tcp" = {};
        "30303/udp" = {};
      };
    };
  }
