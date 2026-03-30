{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem = {
        pkgs,
        self',
        ...
      }: let
        commonArgs = {
          version = "devel";
          src = ./.;
          vendorHash = "sha256-2jNlLq+G8UI6yVb+8Fx5pN8cHT0zsAaz90lrOywDMmk=";
          ldflags = [
            "-extldflags '-static -s -w'"
            "-X 'github.com/metal-stack/v.Version=devel'"
          ];
          tags = ["netgo" "osusergo" "urfave_cli_no_docs"];
        };
      in {
        packages = {
          server = pkgs.buildGoModule (commonArgs
            // {
              pname = "server";
              subPackages = ["cmd/server"];
              postInstall = ''
                mv $out/bin/server $out/bin/go-ipam-server
              '';
            });
          client = pkgs.buildGoModule (commonArgs
            // {
              pname = "client";
              subPackages = ["cmd/client"];
              postInstall = ''
                mv $out/bin/client $out/bin/go-ipam-client
              '';
            });
          default = self'.packages.server;
        };
      };

      flake.nixosModules.default = {self', ...}: {
        environment.systemPackages = [
          self'.packages.server
          self'.packages.client
        ];
      };
    };
}
