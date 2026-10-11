#!/usr/bin/env bash
#
# Generates the two per-deployment secrets and prints a ready-to-fill env file:
#
#   RATATOSK_DATA_KEY          the key that seals every record in ratatosk.db
#   RATATOSK_VAPID_*           the Web Push key pair
#
# Both are unrecoverable if lost, so this writes nothing by itself — it prints,
# and you decide where it goes. See deploy/README.md.
set -euo pipefail

ENV_PATH=${1:-/etc/ratatosk/ratatosk.env}
CONTACT=${RATATOSK_VAPID_CONTACT:-mailto:you@example.org}

# Whether a ratatosk deployment already holds data. Checked in two places: beside
# the env file (a bind mount) and in the named Docker volume this compose file
# uses, because that is where the database actually lives in production.
deployment_has_data() {
  local env_file=$1 dir
  dir=$(dirname "$env_file")

  # Any of these means "there is a deployment with state": the database, or its
  # WAL, or the at-rest key that opens it.
  for candidate in "$dir/ratatosk.db" "$dir/ratatosk.db-wal" "$dir/data-key" \
                   /var/lib/ratatosk/ratatosk.db /opt/arcane/projects/ratatosk/ratatosk.db; do
    [ -e "$candidate" ] && return 0
  done

  # A Docker volume holding the database (production layout). Reading the volume
  # list needs docker, which may not be installed where this runs.
  if command -v docker >/dev/null 2>&1; then
    local projects
    projects=$(docker volume ls --format '{{.Name}}' 2>/dev/null | grep -E 'ratatosk' || true)
    for vol in $projects; do
      if docker run --rm -v "$vol":/d alpine test -e /d/ratatosk.db 2>/dev/null; then
        return 0
      fi
    done
  fi
  return 1
}

# An existing env file is only a problem if the deployment already has data:
# generating fresh keys for a database that exists would make it unreadable.
# A first deploy whose env file happens to be present (a retry, a re-created
# project directory) is fine, so detect the data rather than the file.
if [ -e "$ENV_PATH" ] && deployment_has_data "$ENV_PATH"; then
  cat >&2 <<EOF
refusing to run: $ENV_PATH already exists AND the deployment has data.

Regenerating RATATOSK_DATA_KEY would make the existing database unreadable, and a
new VAPID pair would silently invalidate every device's notification
subscription. Reuse the existing file instead. If you really are starting over,
remove the database and the env file together.
EOF
  exit 1
fi



command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

# 32 random bytes for AES-256-GCM, hex-encoded.
DATA_KEY=$(openssl rand -hex 32)

# A P-256 key pair. The private scalar and the uncompressed public point are
# parsed out of openssl's text output by python rather than by shell string
# surgery: the layout (line breaks, colons, section order) is not a stable
# interface, and a mis-parse here would hand the operator a pair the server
# rejects.
KEYS=$(openssl ecparam -genkey -name prime256v1 -noout 2>/dev/null |
  openssl ec -noout -text 2>/dev/null |
  python3 -c '
import re, sys, base64

text = sys.stdin.read()


def section(name, stop):
    m = re.search(rf"^{name}:\s*(.*?)(?=^{stop}:|\Z)", text, re.S | re.M)
    if not m:
        return None
    return re.sub(r"[^0-9a-fA-F]", "", m.group(1))


priv = section("priv", "pub")          # 32-byte scalar
pub = section("pub", "ASN1 OID")       # 04 || X || Y
if priv is None or pub is None or len(priv) != 64 or len(pub) != 130:
    sys.exit("could not parse a P-256 key pair from openssl output")

b64url = lambda h: base64.urlsafe_b64encode(bytes.fromhex(h)).decode().rstrip("=")
print(b64url(priv))
print(b64url(pub))
')

VAPID_PRIV=$(printf '%s\n' "$KEYS" | sed -n 1p)
VAPID_PUB=$(printf '%s\n' "$KEYS" | sed -n 2p)

[ -n "$VAPID_PRIV" ] && [ -n "$VAPID_PUB" ] || {
  echo "key generation produced nothing" >&2
  exit 1
}

cat <<EOF
# Ratatosk deployment secrets. chmod 600, owned by the service user.
# Copy this to $ENV_PATH

# Seals every record in ratatosk.db. BACK THIS UP with your database backups:
# without it the data cannot be read, and there is no recovery.
RATATOSK_DATA_KEY=$DATA_KEY

# Web Push. Keep this pair for the life of the deployment: changing it
# invalidates every existing notification subscription.
# Omit all three to run with notifications disabled.
RATATOSK_VAPID_PUBLIC_KEY=$VAPID_PUB
RATATOSK_VAPID_PRIVATE_KEY=$VAPID_PRIV
RATATOSK_VAPID_CONTACT=$CONTACT
EOF
