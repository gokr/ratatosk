#!/usr/bin/env bash
# Real server smoke: app serving, contacts, durable messages, restart and
# per-record encryption at rest. Uses an isolated data directory and free port.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p var
DATA=$(mktemp -d "$PWD/var/smoke.XXXXXX")
SRV=
cleanup() {
  if [ -n "$SRV" ]; then kill "$SRV" 2>/dev/null || true; wait "$SRV" 2>/dev/null || true; fi
  rm -rf "$DATA"
}
trap cleanup EXIT
PORT=${PORT:-$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')}
API="http://127.0.0.1:$PORT"
start() {
  ./var/bin/ratatoskd --addr "127.0.0.1:$PORT" --data "$DATA" \
    --public-url "$API" --web app/build/web > "$DATA/server.log" 2>&1 &
  SRV=$!
  for _ in {1..100}; do
    kill -0 "$SRV" 2>/dev/null || { head -80 "$DATA/server.log"; exit 1; }
    if curl -fsS "$API/healthz" > /dev/null 2>&1; then return; fi
    sleep .1
  done
  echo 'server did not become ready' >&2
  exit 1
}
call() {
  curl -fsS -X POST -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $1" -d "$3" "$API/ratatosk.v1.$2"
}
reg() {
  curl -fsS -X POST -H 'Content-Type: application/json' \
    -d "{\"username\":\"$1\",\"password\":\"correct horse battery\",\"displayName\":\"$2\"}" \
    "$API/ratatosk.v1.AuthService/Register" |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])'
}
start
curl -fsS "$API/" > "$DATA/index.html"
grep -q flutter "$DATA/index.html"
ADA=$(reg ada 'Ada Lovelace')
BRU=$(reg brunel 'Isambard Brunel')
INV=$(call "$ADA" SocialService/CreateInvite '{}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["invite"]["url"])')
CONV=$(call "$BRU" SocialService/RedeemInvite "{\"code\":\"$INV\"}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["conversation"]["id"])')
# Deliberately use a plaintext API message to test the independent at-rest seal.
call "$BRU" ChatService/SendMessage "{\"conversationId\":\"$CONV\",\"text\":\"the first message\"}" > /dev/null
kill "$SRV"
wait "$SRV"
SRV=
start
call "$ADA" ChatService/ListConversations '{}' | python3 -c '
import sys,json
c=json.load(sys.stdin)["conversations"][0]
assert c["unreadCount"] == 1, c
assert c["lastMessage"]["text"] == "the first message", c
print("OK: session, conversation and message survived restart")'
python3 - "$DATA" <<'PY'
import pathlib, sqlite3, sys
root=pathlib.Path(sys.argv[1])
dbs=list(root.glob('*.db')) + list(root.glob('*.sqlite*'))
dbs=[p for p in dbs if not p.name.endswith(('-wal','-shm'))]
assert len(dbs)==1, f'expected SQLite database, got {dbs}'
con=sqlite3.connect(dbs[0])
assert con.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
assert con.execute("SELECT count(*) FROM sqlite_master WHERE name='goose_db_version'").fetchone()[0]==1
con.close()
for path in [dbs[0], pathlib.Path(str(dbs[0])+'-wal')]:
    if path.exists():
        raw=path.read_bytes()
        for word in [b'the first message',b'Ada Lovelace',b'brunel']:
            assert word not in raw, f'plaintext leak in {path.name}: {word}'
print('OK: SQLite integrity, goose migrations, encrypted record payloads')
PY
echo 'SMOKE TEST PASSED'
