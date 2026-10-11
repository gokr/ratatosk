#!/usr/bin/env bash
#
# Seed a running server with two accounts, a conversation and a few messages,
# so there is something to look at the moment the app opens.
#
#   make demo          # starts a server on :8080 and seeds it
#
# Sign in as:  ada / correct horse battery   or   brunel / correct horse battery
set -eu
PORT=${PORT:-8080}
API="http://127.0.0.1:$PORT"

reg() {
  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"username\":\"$1\",\"password\":\"$2\",\"displayName\":\"$3\"}" \
    "$API/ratatosk.v1.AuthService/Register" |
    python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))"
}
call() {
  curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $1" -d "$3" \
    "$API/ratatosk.v1.$2"
}

if ! curl -sf -m 2 "$API/healthz" > /dev/null; then
  echo "no server on $API — start one with 'make server' first" >&2
  exit 1
fi

ADA=$(reg ada "correct horse battery" "Ada Lovelace")
BRU=$(reg brunel "correct horse battery" "Isambard Brunel")
[ -n "$ADA" ] && [ -n "$BRU" ] || { echo "could not register (already seeded?)" >&2; exit 1; }

INV=$(call "$ADA" SocialService/CreateInvite '{}' |
  python3 -c "import sys,json;print(json.load(sys.stdin)['invite']['url'])")
CONV=$(call "$BRU" SocialService/RedeemInvite "{\"code\":\"$INV\"}" |
  python3 -c "import sys,json;print(json.load(sys.stdin)['conversation']['id'])")

for m in "Morning — did the bridge hold?" \
         "It did. Last span went in at dawn." \
         "Sending the survey photos when I get signal."; do
  call "$BRU" ChatService/SendMessage "{\"conversationId\":\"$CONV\",\"text\":\"$m\"}" > /dev/null
done

cat <<EOF
Seeded $API

  sign in as   ada    / correct horse battery
               brunel / correct horse battery

Ada has three unread messages from Brunel. Note that their padlock reads
"Not encrypted": Brunel was created from a script, so he has published no
encryption key, and the app refuses to send rather than fall back to plaintext.
Open two real clients (the web app in two browser profiles, or a desktop build
with \`make app DEVICE=linux\`) and invite between them to see sealed messages.
EOF
