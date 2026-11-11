#!/usr/bin/env bash
# Update the packaged Buzz desktop release. Bumps `version` and the fetchurl
# hash in packages/buzz/package.nix; pull-request CI owns build validation.
set -euo pipefail

readonly UPSTREAM_REPO="block/buzz"
readonly UPSTREAM_RELEASES_API="https://api.github.com/repos/${UPSTREAM_REPO}/releases?per_page=30"
readonly PACKAGE="packages/buzz/package.nix"

log() { printf '[buzz-update] %s\n' "$*" >&2; }
die() { printf '[buzz-update] ERROR: %s\n' "$*" >&2; exit 2; }

usage() {
  cat <<'USAGE'
Usage: scripts/update-buzz.sh [OPTIONS]

Options:
  --check          Exit 1 if an upstream desktop release is newer
  --version VER    Update to a specific version, e.g. 0.5.28
  --help           Show this help
USAGE
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

current_version() {
  sed -n 's/^  version = "\([^"]*\)";/\1/p' "$PACKAGE"
}

releases_json() {
  if [ -n "${GH_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
    gh api "repos/${UPSTREAM_REPO}/releases?per_page=30"
  elif command -v gh >/dev/null 2>&1; then
    gh api "repos/${UPSTREAM_REPO}/releases?per_page=30" 2>/dev/null || curl -fsSL "$UPSTREAM_RELEASES_API"
  else
    curl -fsSL "$UPSTREAM_RELEASES_API"
  fi
}

latest_release_json() {
  releases_json | jq -cer '
    map(select(
      (.draft | not)
      and (.prerelease | not)
      and (.tag_name | test("^desktop-v[0-9]+\\.[0-9]+\\.[0-9]+$"))
      and ([.assets[].name] | any(endswith("_amd64.deb")))
    ))
    | sort_by(.published_at // .created_at)
    | last
    // error("no stable desktop release with an amd64 deb asset found")
  '
}

restore_on_failure() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -n "${TMPDIR_UPDATE:-}" ] && [ -d "$TMPDIR_UPDATE" ]; then
    cp "$TMPDIR_UPDATE/package.nix" "$PACKAGE"
  fi
  exit "$status"
}

main() {
  local check_only=false
  local target=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --check) check_only=true; shift ;;
      --version) target="$2"; shift 2 ;;
      --help) usage; exit 0 ;;
      *) die "unknown option: $1" ;;
    esac
  done

  [ -f flake.nix ] && [ -f "$PACKAGE" ] || die "run from buzz-flake root"
  need nix
  need jq

  local current latest
  current="$(current_version)"
  if [ -n "$target" ]; then
    latest="$target"
  else
    latest="$(latest_release_json | jq -r '.tag_name' | sed -n 's/^desktop-v//p')"
  fi

  [[ "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "latest version is malformed: $latest"

  log "current: $current"
  log "latest:  $latest"

  if [ "$current" = "$latest" ]; then
    log "already up to date"
    exit 0
  fi

  if [ "$check_only" = true ]; then
    log "update available: $current -> $latest"
    exit 1
  fi

  TMPDIR_UPDATE="$(mktemp -d)"
  export TMPDIR_UPDATE
  trap restore_on_failure EXIT
  cp "$PACKAGE" "$TMPDIR_UPDATE/package.nix"

  local url hash
  url="https://github.com/${UPSTREAM_REPO}/releases/download/desktop-v${latest}/Buzz_${latest}_amd64.deb"
  log "prefetching $url..."
  hash="$(nix store prefetch-file --json "$url" | jq -r .hash)"
  [ -n "$hash" ] && [ "$hash" != "null" ] || die "prefetch failed"

  sed -i -e "s/^  version = \"[^\"]*\";/  version = \"${latest}\";/" "$PACKAGE"
  sed -i -e "s|^    hash = \"sha256-[^\"]*\";|    hash = \"${hash}\";|" "$PACKAGE"

  trap - EXIT
  rm -rf "$TMPDIR_UPDATE"
  git diff --stat "$PACKAGE" 2>/dev/null || true
}

main "$@"
