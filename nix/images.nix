{
  system,
  pkgs,
  ...
}: let
  spec = builtins.fromJSON (builtins.readFile ./images.json);

  srcFetchers = [
    # Add fetchers here if we need more than github support.
    # Each fetcher needs to have a repositoryFmt and a fetcher function.
    # The fetcher function will be called with the parts from matching
    # the repositoryFmt, in addition to revision and sha256.
    {
      repositoryFmt = "https://github.com/([^/]+)/([^/]+)";
      fetcher = {
        parts,
        revision,
        sha256,
      }: let
        owner = builtins.elemAt parts 0;
        repo = builtins.elemAt parts 1;
      in
        pkgs.fetchFromGitHub {
          inherit owner repo sha256;
          rev = revision;
        };
    }
  ];

  srcFetcherFor = repository: let
    selectFirst = a: b:
      if a == null
      then b
      else a;
    extract = {
      repositoryFmt,
      fetcher,
    }: let
      parts = builtins.match repositoryFmt repository;
    in
      if parts != null
      then {inherit fetcher parts;}
      else null;
  in
    # select the first matching fetcher
    builtins.foldl' selectFirst null (map extract srcFetchers);

  imageSrc = {
    repository,
    revision,
    sha256,
  }: let
    res = srcFetcherFor repository;
  in
    if res == null
    then null
    else
      res.fetcher {
        parts = res.parts;
        inherit revision sha256;
      };

  # Enforce tagging and content convention for the images.
  imageBuilderFor = name: rev: args:
    pkgs.dockerTools.buildImage (args
      // {
        name = "nix-${name}";
        tag = rev;

        copyToRoot =
          args.copyToRoot
          ++ [
            # we need basic shell capabilities
            pkgs.dash
            pkgs.coreutils
            # add CA certificates for convenience
            pkgs.cacert
          ];
      });

  optionalImg = name:
    if builtins.hasAttr name spec
    then {
      ${name} = let
        imgSpec = spec.${name};
      in
        pkgs.callPackage ./definitions/${name}.nix {
          inherit system pkgs;
          imageBuilder = imageBuilderFor name imgSpec.revision;
          src = imageSrc imgSpec;
        };
    }
    else {};

  supportedImages = let
    definitionsDir = ./definitions;
    files = builtins.readDir definitionsDir;
    isNixFile = name: value: value == "regular" && builtins.match ".*\\.nix$" name != null;
    nixFiles = builtins.filter (name: isNixFile name (files.${name})) (builtins.attrNames files);
    stripNix = name: builtins.substring 0 (builtins.stringLength name - 4) name;
  in
    map stripNix nixFiles;
in
  builtins.foldl' (a: b: a // b) {} (map optionalImg supportedImages)
