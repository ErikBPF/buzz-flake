#!/usr/bin/env bash
set -euo pipefail

grep -q 'bin/buzz-desktop' checks.nix
grep -q 'programs.buzz.enable = true' checks.nix
grep -q 'home.packages = \[cfg.package\] ++ cfg.acpAdapters' modules/home-manager.nix
grep -q 'pkgs.codex-acp pkgs.claude-agent-acp' modules/home-manager.nix
grep -q 'bin/buzz-acp' checks.nix
grep -q 'bin/buzz-dev-mcp' checks.nix
grep -Fq 'releases/download/desktop-v${version}/Buzz_${version}_amd64.deb' packages/buzz/package.nix
test -f .github/workflows/check.yml
grep -q 'bash tests/contracts.sh' .github/workflows/check.yml
grep -q 'nix flake check' .github/workflows/check.yml
