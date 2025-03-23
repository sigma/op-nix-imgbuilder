{
  pkgs,
  src,
  imageBuilder,
  ...
}: let
  op-reth = pkgs.stdenv.mkDerivation {
    name = "op-reth";
    inherit src;

    nativeBuildInputs = with pkgs; [
      cacert
      cargo
      clang
      llvmPackages.libclang
      llvmPackages.libcxxClang
      perl
    ];

    LIBCLANG_PATH = with pkgs; "${llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = with pkgs; "-isystem ${llvmPackages.libclang.lib}/lib/clang/${lib.versions.major (lib.getVersion clang)}/include";

    buildPhase = ''
      # set HOME to a valid directory for cargo
      HOME=$TMPDIR ${pkgs.gnumake}/bin/make install-op
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp $TMPDIR/.cargo/bin/op-reth $out/bin/
    '';
  };
in
  imageBuilder {
    copyToRoot = [
      op-reth
    ];
    config = {
      ExposedPorts = {
        "7545/tcp" = {};
        "8545/tcp" = {};
        "8546/tcp" = {};
        "8551/tcp" = {};
        "9001/tcp" = {};
        "30303/tcp" = {};
        "30303/udp" = {};
      };
    };
  }
