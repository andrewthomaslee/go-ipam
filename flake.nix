{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      # imports = [
      #   (inputs.import-tree ./modules)
      # ];

      # Terranix Main Entrypoint
      perSystem = {
        pkgs,
        inputs',
        self',
        ...
      }: let
        inherit (inputs) self lib;
      in {
        packages.default = {};
      };
    };
}
