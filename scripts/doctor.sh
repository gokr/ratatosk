#!/usr/bin/env bash
#
# Report what is ready and what is missing, changing nothing.
#
#   make doctor
set -u

cd "$(dirname "$0")/.." || exit 1
ROOT=$(pwd)

found() { printf '  \033[32mok\033[0m      %s\n' "$*"; }
lost()  { printf '  \033[31mmissing\033[0m %s\n' "$*"; }
info()  { printf '  %s\n' "$*"; }

# Tool paths recorded by scripts/setup.sh, if it has run.
[ -f "$ROOT/var/tools/env" ] && . "$ROOT/var/tools/env"

v() { "$@" 2>/dev/null | head -1; }
present() { command -v "$1" > /dev/null 2>&1; }

echo
echo "Toolchains"
report_tool() {
  local label=$1 path=$2
  if [ -n "$path" ] && [ -x "$path" ]; then
    found "$label  $path"
  elif present "$label"; then
    found "$label  $(command -v "$label")"
  else
    lost "$label"
  fi
}
report_tool go "${GO:-}"
report_tool flutter "${FLUTTER:-}"
report_tool dart "${DART:-}"
report_tool buf "${BUF:-}"

echo
echo "Generators (var/tools, or on PATH)"
for g in protoc-gen-go protoc-gen-connect-go protoc-gen-dart protoc-gen-connect-dart; do
  if [ -x "$ROOT/var/tools/$g" ]; then found "$g (var/tools)"
  elif present "$g"; then found "$g ($(command -v "$g"))"
  else lost "$g"; fi
done

echo
echo "Build state"
[ -x "$ROOT/var/bin/ratatoskd" ] && found "server binary built" || info "server binary not built yet (make build-server)"
if [ -f "$ROOT/app/build/web/index.html" ]; then
  found "web app built ($(du -sh "$ROOT/app/build/web" 2>/dev/null | cut -f1))"
else
  info "web app not built yet (make web)"
fi
[ -f "$ROOT/app/pubspec.lock" ] && found "flutter packages resolved" || info "run make setup"
[ -f "$ROOT/server/go.sum" ] && found "go modules resolved" || info "run make setup"

echo
echo "Runtime state"
if [ -d "$ROOT/var/data" ]; then
  found "data directory $ROOT/var/data"
  if [ -f "$ROOT/var/data/ratatosk.json" ]; then
    info "snapshot is $(head -c 15 "$ROOT/var/data/ratatosk.json" | tr -d '\n')  (RATATOSK-ENC-1 means sealed)"
  fi
  if [ -f "$ROOT/var/data/data-key" ]; then
    info "data key present, mode $(stat -c '%a' "$ROOT/var/data/data-key" 2>/dev/null)"
  fi
else
  info "no data directory yet (created on first run)"
fi

echo
echo "Platform"
if [ "$(uname -s)" = "Linux" ]; then
  if pkg-config --exists libsecret-1 2>/dev/null; then
    found "libsecret-1-dev (Linux desktop builds)"
  else
    info "libsecret-1-dev not installed: web builds are fine, desktop needs it"
    info "  sudo apt install libsecret-1-dev"
  fi
fi
if present google-chrome || present chromium; then
  found "a Chrome/Chromium (flutter run -d chrome, flutter test --platform chrome)"
fi
if ! present jq && ! present python3; then
  info "neither jq nor python3 on PATH: scripts/verify-run.sh needs one of them"
fi

echo
CMD="go"
[ -n "${GO:-}" ] && CMD="$GO"
"$CMD" version > /dev/null 2>&1 && found "go is usable" || info "go not usable from here"
echo
