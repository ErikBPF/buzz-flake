{
  description = "Buzz desktop, CLI, and ACP harness for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        buzz = pkgs.callPackage ./packages/buzz/package.nix {};
      in {
        packages = {
          default = buzz;
          inherit buzz;
        };
        apps.default = {
          type = "app";
          program = "${buzz}/bin/buzz-desktop";
        };
        checks = import ./checks.nix {inherit inputs pkgs self system;};
        formatter = pkgs.alejandra;
      };

      flake.homeManagerModules = {
        default = import ./modules/home-manager.nix;
        withPackage = {pkgs, ...}: {
          imports = [self.homeManagerModules.default];
          programs.buzz.package = self.packages.${pkgs.stdenv.hostPlatform.system}.buzz;
        };
      };
    };
}
