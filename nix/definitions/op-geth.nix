{
  pkgs,
  spec,
  ...
}: let
  src = pkgs.fetchFromGitHub spec;

  op-geth = pkgs.stdenv.mkDerivation {
    name = "op-geth";
    inherit src;

    nativeBuildInputs = with pkgs; [
      go
      gnumake
    ];

    buildPhase = ''
      make geth
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp build/bin/geth $out/bin/
    '';
  };

  alpine = pkgs.dockerTools.pullImage {
    imageName = "alpine";
    imageDigest = "sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b";
    sha256 = "sha256-ZZyGGZqKk0MIHiH/ktUyuEHVKCT6vqK5ZMiQVRB8X9g=";
    finalImageTag = "latest";
  };
in
  pkgs.dockerTools.buildImage {
    name = "nix-op-geth";
    tag = spec.revision;
    fromImage = alpine;
    copyToRoot = [
      op-geth
      pkgs.cacert
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
