# buzz-flake

Nix package and Home Manager module for [Buzz](https://github.com/block/buzz).

```nix
inputs.buzz-flake.url = "github:ErikBPF/buzz-flake";

imports = [inputs.buzz-flake.homeManagerModules.withPackage];
programs.buzz.enable = true;
```

The module installs Buzz's desktop/CLI/ACP binaries plus the Codex and Claude
ACP adapters. Buzz discovers OpenCode (`opencode acp`) and Hermes
(`hermes-acp`) directly when those existing packages are on `PATH`.
