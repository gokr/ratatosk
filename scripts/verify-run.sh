#!/usr/bin/env bash
#
# Verify the documented startup from a clean data directory: build artefacts in
# place, then check that the server serves the app, that two accounts can
# register, that an invitation link connects them, that a message arrives with
# the right unread count — and that the store the server leaves behind is sealed
# and contains none of the plaintext.
#
# Run it with `make smoke`. It uses its own port and data directory, so it does
# not disturb a server you already have running, and it cleans up after itself.
set -u
cd "$(dirname "$0")/.." || exit 1
PORT=${PORT:-8099}
API="http://127.0.0.1:$PORT"

# Stop whatever holds the port, by pid: matching on a command line here would
# also match this script's own invocation.
pid=$(ss -ltnp 2>/dev/null | grep ":$PORT " | grep -oP 'pid=\K[0-9]+' | head -1)
[ -n "$pid" ] && kill "$pid" && sleep 1

DATA=var/smoke-data
rm -rf "$DATA" var/smoke.log
./var/bin/ratatoskd --addr "127.0.0.1:$PORT" --data "$DATA" \
  --public-url "$API" --web app/build/web > var/smoke.log 2>&1 &
SRV=$!
sleep 3

echo "--- what the server says on startup ---"
head -2 var/smoke.log

echo "--- the app is served at / ---"
curl -s -o /dev/null -w "GET / -> %{http_code}, %{size_download} bytes, %{content_type}\n" "$API/"

reg() {
  curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"username\":\"$1\",\"password\":\"$2\",\"displayName\":\"$3\"}" \
    "$API/ratatosk.v1.AuthService/Register" |
    python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))"
}
call() {
  curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $1" -d "$3" "$API/ratatosk.v1.$2"
}

ADA=$(reg ada "correct horse battery" "Ada Lovelace")
BRU=$(reg brunel "correct horse battery" "Isambard Brunel")
echo "--- two accounts registered ---"
echo "ada token: ${ADA:0:10}…  brunel token: ${BRU:0:10}…"

INV=$(call "$ADA" SocialService/CreateInvite '{}' | python3 -c "import sys,json;print(json.load(sys.stdin)['invite']['url'])")
echo "--- ada's invitation link: $INV ---"

CONV=$(call "$BRU" SocialService/RedeemInvite "{\"code\":\"$INV\"}" | python3 -c "import sys,json;print(json.load(sys.stdin)['conversation']['id'])")
echo "--- brunel redeemed it; conversation $CONV ---"

call "$BRU" ChatService/SendMessage "{\"conversationId\":\"$CONV\",\"text\":\"the first message\"}" >/dev/null
echo "--- ada's unread count and last message ---"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $ADA" -d '{}' \
  "$API/ratatosk.v1.ChatService/ListConversations" |
  python3 -c "
import sys,json
c=json.load(sys.stdin)['conversations'][0]
print(f\"  {c['title']}: unread={c['unreadCount']} last={c['lastMessage']['text']!r}\")"

# The store debounces writes (500ms) and always flushes on shutdown, so the
# snapshot is inspected after the server has stopped.
kill $SRV 2>/dev/null
wait $SRV 2>/dev/null
echo "--- server stopped (it flushes the store on the way out) ---"

echo "--- the data directory the server keeps ---"
ls -1 "$DATA"
echo -n "  snapshot starts with: "; head -c 16 "$DATA/ratatosk.json"; echo
for word in "the first message" "Ada Lovelace" brunel; do
  if grep -rqa "$word" "$DATA/ratatosk.json"; then echo "  PLAINTEXT LEAK: $word"; else echo "  absent from the snapshot: $word"; fi
done

echo "--- done; cleaning up ---"
rm -rf "$DATA" var/smoke.log
