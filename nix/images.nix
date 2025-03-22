{
  system,
  pkgs,
  ...
}: let
  spec = builtins.fromJSON (builtins.readFile ./images.json);

  imageSpec = {
    repository,
    revision,
    sha256,
  }: let
    # extend this if we need more than github
    parts = builtins.match "https://github.com/([^/]+)/([^/]+)" repository;
    owner = builtins.elemAt parts 0;
    repo = builtins.elemAt parts 1;
  in {
    inherit owner repo sha256;
    rev = revision;
  };

  optionalImg = name:
    if builtins.hasAttr name spec
    then {
      ${name} = pkgs.callPackage ./definitions/${name}.nix {
        inherit system pkgs;
        spec = imageSpec spec.${name};
      };
    }
    else {};

  images = [
    "op-geth"
  ];
in
  builtins.foldl' (a: b: a // b) {} (map optionalImg images)
