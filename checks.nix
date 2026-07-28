{
  inputs,
  pkgs,
  self,
  system,
}: let
  testPkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  hm = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = testPkgs;
    modules = [
      self.homeManagerModules.withPackage
      {
        home = {
          username = "test";
          homeDirectory = "/home/test";
          stateVersion = "25.11";
        };
        programs.buzz.enable = true;
      }
    ];
  };
in {
  package = pkgs.runCommand "buzz-package-check" {} ''
    ${self.packages.${system}.buzz}/bin/buzz --help >/dev/null
    ${self.packages.${system}.buzz}/bin/buzz-acp --help >/dev/null
    test -x ${self.packages.${system}.buzz}/bin/buzz-dev-mcp
    test -x ${self.packages.${system}.buzz}/bin/buzz-desktop
    touch "$out"
  '';
  module = hm.activationPackage;
}
