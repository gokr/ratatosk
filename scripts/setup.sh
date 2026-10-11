#!/usr/bin/env bash
#
# Install what this repository needs to build and generate code.
#
# Deliberately self-contained: everything lands in the project's own `var/tools`
# directory, and the resolved tool paths are written to `var/tools/env`, which
# the Makefile includes. Nothing here edits your shell configuration, and no
# step needs sudo — a prerequisite that is missing and cannot be installed
# without root is reported instead of installed.
#
#   make setup      install/check everything
#   make doctor     report only, change nothing
set -u

cd "$(dirname "$0")/.." || exit 1
ROOT=$(pwd)
TOOLS="$ROOT/var/tools"
# Pinned rather than "latest": a code generator that silently changes version
# between two runs on the same commit makes generated files unexplainable. Set
# BUF_VERSION=… to use another one.
BUF_VERSION=${BUF_VERSION:-1.73.0}

mkdir -p "$TOOLS"
FAILED=0
NOTE=""

say()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
warn() { printf '  \033[33mwarn\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mmissing\033[0m %s\n' "$*"; }

# --- find the toolchains -----------------------------------------------------

# Resolve a command by name, or in the places a normal install puts it.
find_cmd() {
  local name=$1; shift
  local found
  found=$(command -v "$name" 2>/dev/null) && { echo "$found"; return; }
  for candidate in "$@"; do
    [ -x "$candidate" ] && { echo "$candidate"; return; }
  done
}

GO=$(find_cmd go /usr/local/go/bin/go /usr/lib/go/bin/go "$HOME/go/bin/go" /opt/homebrew/bin/go)
DART=$(find_cmd dart "$HOME/.pub-cache/bin/dart" /usr/lib/dart/bin/dart /opt/homebrew/bin/dart)
FLUTTER=$(find_cmd flutter "$HOME/flutter/bin/flutter" /opt/flutter/bin/flutter /opt/homebrew/bin/flutter)

echo
echo "Checking the toolchains"

if [ -n "$GO" ]; then
  ok "go $( "$GO" version | awk '{print $3}' )  ($GO)"
else
  bad "go — install it from https://go.dev/dl/ (and put it on PATH)"
  FAILED=1
fi

if [ -n "$FLUTTER" ]; then
  ok "flutter $( "$FLUTTER" --version 2>/dev/null | head -1 | awk '{print $2}' )  ($FLUTTER)"
  # The Dart SDK ships inside Flutter; prefer the one that matches it.
  [ -z "$DART" ] && DART=$(dirname "$FLUTTER")/dart
else
  bad "flutter — install it from https://docs.flutter.dev/install/manual"
  FAILED=1
fi

if [ -n "$DART" ] && [ -x "$DART" ]; then
  ok "dart $( "$DART" --version 2>/dev/null | awk '{print $4}' )  ($DART)"
fi

# --- buf ---------------------------------------------------------------------

echo
echo "Installing the code generators"

# Prefer a buf that is already on PATH; otherwise fetch the pinned release into
# var/tools so this repository carries its own copy.
BUF=$(find_cmd buf "$TOOLS/buf")
if [ -n "$BUF" ]; then
  ok "buf $( "$BUF" --version )  ($BUF)"
else
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)   BUF_ASSET=buf-Linux-x86_64 ;;
    Linux-aarch64)  BUF_ASSET=buf-Linux-aarch64 ;;
    Darwin-x86_64)  BUF_ASSET=buf-Darwin-x86_64 ;;
    Darwin-arm64)   BUF_ASSET=buf-Darwin-arm64 ;;
    *)              BUF_ASSET="" ;;
  esac
  if [ -z "$BUF_ASSET" ]; then
    bad "buf — no prebuilt release for $(uname -s)/$(uname -m); install it from https://buf.build/docs/installation"
    FAILED=1
  elif ! command -v curl > /dev/null; then
    bad "buf — needs curl to download; install curl or buf itself"
    FAILED=1
  else
    say "downloading buf $BUF_VERSION for $(uname -s)/$(uname -m) …"
    url="https://github.com/bufbuild/buf/releases/download/v$BUF_VERSION/$BUF_ASSET.tar.gz"
    # The archive's internal layout has changed between releases (buf/bin/buf in
    # some, buf-Linux-x86_64/bin/buf in others), so extract it as it comes and
    # then look for the binary rather than pattern-matching the path.
    rm -rf "$TOOLS/buf-unpack"
    mkdir -p "$TOOLS/buf-unpack"
    if curl -sSL --fail -o "$TOOLS/buf.tar.gz" "$url" \
       && tar xzf "$TOOLS/buf.tar.gz" -C "$TOOLS/buf-unpack" \
       && BUGBIN=$(find "$TOOLS/buf-unpack" -type f -name buf -perm -u+x | head -1) \
       && [ -n "$BUGBIN" ]; then
      cp -f "$BUGBIN" "$TOOLS/buf"
      chmod +x "$TOOLS/buf"
      rm -rf "$TOOLS/buf-unpack" "$TOOLS/buf.tar.gz"
      BUF="$TOOLS/buf"
      ok "buf $( "$BUF" --version )  ($BUF)"
    else
      bad "buf — could not download or unpack $url"
      FAILED=1
    fi
  fi
fi

# The Go plugins: GOBIN points straight at var/tools, so they never have to be
# on anyone's PATH.
if [ -n "$GO" ]; then
  for plugin in google.golang.org/protobuf/cmd/protoc-gen-go connectrpc.com/connect/cmd/protoc-gen-connect-go; do
    name=$(basename "$plugin")
    if [ -x "$TOOLS/$name" ] && [ -z "${FORCE:-}" ]; then
      ok "$name (already installed)"
    elif (cd "$ROOT/server" && GOBIN="$TOOLS" "$GO" install "$plugin" > /dev/null 2>&1); then
      ok "$name"
    else
      bad "$name — '$GO' install $plugin' failed"
      FAILED=1
    fi
  done
fi

# The Dart plugins land in the pub cache; copy them next to the others so the
# generator invocation has one directory to search.
if [ -n "$DART" ] && [ -x "$DART" ]; then
  for pkg in protoc_plugin connectrpc; do
    bin=$(echo "$pkg" | sed 's/protoc_plugin/protoc-gen-dart/;s/connectrpc/protoc-gen-connect-dart/')
    if [ -x "$TOOLS/$bin" ] && [ -z "${FORCE:-}" ]; then
      ok "$bin (already installed)"
      continue
    fi
    if ! "$DART" pub global activate "$pkg" > /dev/null 2>&1; then
      bad "$bin — 'dart pub global activate $pkg' failed (no network?)"
      FAILED=1
      continue
    fi
    # The cache location is the SDK's business; ask the package manager for it.
    cache=$("$DART" pub global list > /dev/null 2>&1; echo "${PUB_CACHE:-$HOME/.pub-cache}/bin")
    if [ -x "$cache/$bin" ]; then
      cp -f "$cache/$bin" "$TOOLS/$bin" 2>/dev/null || ln -sf "$cache/$bin" "$TOOLS/$bin"
      ok "$bin"
    else
      bad "$bin — activated, but not found in $cache"
      FAILED=1
    fi
  done
fi

# --- dependencies ------------------------------------------------------------

echo
echo "Fetching dependencies"

if [ -n "$GO" ]; then
  if (cd "$ROOT/server" && "$GO" mod download > /dev/null 2>&1); then
    ok "go modules"
  else
    bad "go modules — 'go mod download' failed (no network?)"
    FAILED=1
  fi
fi

if [ -n "$FLUTTER" ]; then
  if (cd "$ROOT/app" && "$FLUTTER" pub get > /dev/null 2>&1); then
    ok "flutter packages"
  else
    bad "flutter packages — 'flutter pub get' failed"
    FAILED=1
  fi
fi

# --- platform notes ----------------------------------------------------------

echo
echo "Platform notes"

if [ "$(uname -s)" = "Linux" ]; then
  if pkg-config --exists libsecret-1 2>/dev/null; then
    ok "libsecret-1-dev (needed to build the Linux desktop app)"
  else
    warn "libsecret-1-dev is missing: the web app builds without it, the Linux"
    warn "  desktop app does not (the private keys go in the platform keystore)."
    warn "  Install it with:  sudo apt install libsecret-1-dev"
    NOTE="yes"
  fi
fi

# --- record what we found ----------------------------------------------------

# The Makefile includes this, so every target uses the same toolchain this script
# resolved, whether or not it is on the caller's PATH. It is a file under var/
# (gitignored), not a change to anyone's environment.
#
# Written as `KEY=value` with no spaces on purpose: that is valid in both make
# and a POSIX shell, so scripts/doctor.sh can source the same file.
cat > "$TOOLS/env" <<EOF
# Written by scripts/setup.sh — resolved tool paths for this checkout.
GO=$GO
DART=$DART
FLUTTER=$FLUTTER
BUF=$BUF
TOOLS=$TOOLS
EOF
echo
ok "wrote $TOOLS/env"

if [ "$FAILED" = "1" ]; then
  echo
  echo "Some prerequisites are missing — see the lines above."
  exit 1
fi

echo
echo "Ready. Next:"
echo "  make proto      regenerate the Go and Dart code from proto/"
echo "  make server     build everything and serve the app on http://localhost:8080"
[ -n "$NOTE" ] && echo "  (and install libsecret-1-dev if you want the desktop app)"
exit 0
