#!/usr/bin/env bash
#
# Renders privacy_policy.md to the PDF the server publishes at
# https://<host>/privacy_policy.pdf
#
#   scripts/generate-privacy-pdf.sh
#
# pandoc turns the Markdown into styled HTML and headless Chrome prints it, which
# avoids a LaTeX toolchain: the only requirements are pandoc and a Chrome/Chromium
# binary, both of which are common enough not to be a burden. The output is
# committed, so a deploy does not need either tool.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=privacy_policy.md
OUT=app/web/privacy_policy.pdf
HTML=$(mktemp --suffix=.html)
trap 'rm -f "$HTML"' EXIT

[ -f "$SRC" ] || { echo "missing $SRC" >&2; exit 1; }

CHROME=${CHROME:-}
if [ -z "$CHROME" ]; then
  for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then CHROME=$candidate; break; fi
  done
fi
[ -n "$CHROME" ] || { echo "no Chrome/Chromium found (set CHROME=...)" >&2; exit 1; }
command -v pandoc >/dev/null || { echo "pandoc is required" >&2; exit 1; }

# Styling is inline so the HTML file is self-contained: Chrome prints it without
# fetching anything, and there is no stylesheet to keep in sync.
pandoc "$SRC" \
  --from=gfm \
  --to=html5 \
  --standalone \
  --metadata title="Ratatosk Privacy Policy" \
  --include-in-header=/dev/stdin \
  --output="$HTML" <<'CSS'
<style>
  @page { size: A4; margin: 20mm 18mm; }
  body {
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    font-size: 11pt; line-height: 1.55; color: #111; max-width: 100%;
  }
  h1 { font-size: 20pt; margin: 0 0 4pt; }
  h2 { font-size: 13pt; margin: 18pt 0 6pt; }
  p, li { margin: 4pt 0; }
  ul { padding-left: 18pt; }
  a { color: #114dfe; text-decoration: none; }
  strong { font-weight: 600; }
  /* Keep headings with their text, which is the usual reason a generated PDF
     looks wrong: a section title stranded at the foot of a page. */
  h1, h2 { break-after: avoid; page-break-after: avoid; }
  p, li { break-inside: avoid; page-break-inside: avoid; }
</style>
CSS

# --no-pdf-header-footer suppresses Chrome's own print furniture (a date, the
# page title and a page number); a published policy should not carry a timestamp
# from whenever it happened to be generated.
"$CHROME" --headless --disable-gpu --no-sandbox \
  --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw \
  --virtual-time-budget=5000 \
  --print-to-pdf="$PWD/$OUT" \
  "file://$HTML" >/dev/null 2>&1

[ -s "$OUT" ] || { echo "chrome produced no PDF" >&2; exit 1; }
printf 'wrote %s (%s bytes)\n' "$OUT" "$(stat -c%s "$OUT")"
