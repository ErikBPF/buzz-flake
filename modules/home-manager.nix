{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.buzz;
in {
  options.programs.buzz = {
    enable = lib.mkEnableOption "Buzz desktop and agent tools";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.buzz;
    };
    acpAdapters = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [pkgs.codex-acp pkgs.claude-agent-acp];
      description = "ACP adapters made visible to Buzz runtime discovery.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package] ++ cfg.acpAdapters;
  };
}
