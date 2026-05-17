{
  inputs.nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
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
      server = pkgs.buildGoModule (commonArgs
        // {
          pname = "server";
          subPackages = ["cmd/server"];
        });
      client = pkgs.buildGoModule (commonArgs
        // {
          pname = "client";
          subPackages = ["cmd/client"];
        });
      default = pkgs.symlinkJoin {
        name = "go-ipam";
        paths = [
          self.packages.${system}.server
          self.packages.${system}.client
        ];
      };
    });

    nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }:
      with lib; let
        cfg = config.services.go-ipam;
        system = pkgs.stdenv.hostPlatform.system;
      in {
        options.services.go-ipam = {
          enable = mkEnableOption "go-ipam server";
          redis.port = mkOption {
            type = types.int;
            default = 6379;
          };
        };

        config = mkIf cfg.enable {
          services.redis.servers.go-ipam = {
            enable = true;
            inherit (cfg.redis) port;
          };

          systemd.services.go-ipam = {
            description = "go-ipam server";
            wantedBy = ["multi-user.target"];
            after = ["redis-go-ipam.service"];
            wants = ["redis-go-ipam.service"];
            serviceConfig = {
              ExecStart = "${self.packages.${system}.server}/bin/server redis --host 127.0.0.1 --port ${toString cfg.redis.port}";
              DynamicUser = true;
              Restart = "on-failure";
            };
          };

          environment.systemPackages = [
            self.packages.${system}.server
            self.packages.${system}.client
          ];
        };
      };
  };
}
