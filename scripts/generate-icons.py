#!/usr/bin/env python3
"""Regenerate committed launcher assets from the supplied artwork (Pillow).

Run after replacing `Blue Squirrel Messenger Icon.png`:

    python3 scripts/generate-icons.py

The artwork is a blue plate inside a thin white margin, so the interesting
content is smaller than the file. Anything that gets *masked* by the platform —
Android's adaptive icons, the web's maskable icons — is therefore built from a
crop of the plate rather than the whole square: scaling the full square down to
the safe zone is what leaves a wide band of empty margin around a small logo.
"""
import json
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
art = Image.open(root / 'Blue Squirrel Messenger Icon.png').convert('RGB')

# Content bounds: everything that is not the near-white margin.
_w, _h = art.size
_px = art.load()
xs, ys = [], []
for y in range(0, _h, 2):
    for x in range(0, _w, 2):
        if min(_px[x, y]) < 235:
            xs.append(x)
            ys.append(y)
BOX = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
PLATE = art.crop(BOX)
bw = (BOX[2] - BOX[0]) / _w
bh = (BOX[3] - BOX[1]) / _h
# Two colours matter. The plate's is sampled from its middle, not a corner: the
# plate is a rounded square, so the corners of its bounding box are still margin.
PLATE_COLOR = PLATE.getpixel((PLATE.width // 2, PLATE.height // 2))
PLATE_HEX = '#%02X%02X%02X' % PLATE_COLOR
# The margin is the design's background, and it is what makes the blue plate read
# as a speech bubble rather than a full-bleed square. A masked icon therefore keeps
# a ring of it.
MARGIN_COLOR = art.getpixel((2, 2))
MARGIN_HEX = '#%02X%02X%02X' % MARGIN_COLOR

# How much of a masked canvas the plate should cover — taken from the artwork
# itself rather than chosen, because the margin *is* the design: the plate is a
# speech bubble on a light field, and that outline is what makes it read as one.
#
# Getting this wrong is visible in both directions. Scale the whole square down to
# the maskable safe zone and the plate shrinks to about 45% and the icon is a small
# tile in a sea of white; crop the plate to the full canvas and the outline
# disappears, leaving a plain blue square. Measured, the plate is ~79.5% of the
# artwork, which is just inside the ~80% circle a launcher crops to: the bubble
# touches the circle at the cardinal edges and the margin shows between the bubble's
# rounded corners and the circle, which is how the design is drawn.
PLATE_FRACTION = round(max(bw, bh), 4)

# A masked canvas is cropped to a circle, and the artwork's corners — where the
# bubble's tail and its rounded corners live — are the furthest thing from the
# centre. This value is chosen so they stay clear of that crop.
#
# Measured as "furthest content pixel from the centre, over the disc radius", where
# 1.00 means the mask cuts the artwork:
#
#     0.795 (the artwork's own proportion)  clipped
#     0.70   7.5% clearance   — reported as still cutting the tail on Android
#     0.66  12.8% clearance   — used here
#     0.64  15.3% clearance
#
# 0.70 cleared in my simulation and still looked cut on a real device, which is the
# useful lesson: a launcher's visible circle, its own insets and antialiasing at
# small sizes all eat into a margin that a pixel measurement calls sufficient. So
# the target is a real ring of margin, not the technical absence of a cut, and
# install_assets_test asserts at least 10% clearance.
#
# iOS is not masked at all, so it keeps PLATE_FRACTION and the full artwork.
MASKED_PLATE_FRACTION = 0.66


def _scaled(source, size):
    return source.resize((size, size), Image.Resampling.LANCZOS)


def save(path, size, source=None, fill=1.0, background=None, transparent=False):
    """Write `size`x`size`, drawing `source` (default: the whole artwork).

    `transparent` leaves everything outside `source` unpainted, which is what an
    Android adaptive foreground layer wants: the launcher composites it over the
    background colour and then applies its own mask.
    """
    source = source if source is not None else art
    if transparent:
        out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    else:
        out = Image.new('RGB', (size, size), background or MARGIN_COLOR)
    inner = max(1, round(size * fill))
    scaled = _scaled(source, inner).convert('RGBA') if transparent else _scaled(source, inner)
    out.paste(scaled, ((size - inner) // 2, (size - inner) // 2),
              scaled if transparent else None)
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    out.save(target)


# --- in-app mark: the full artwork, as iOS shows it and as it looks best ----
save('app/assets/brand/logo.png', 512)

# --- web -------------------------------------------------------------------
# Non-maskable icons are shown as-is, so the full artwork is right (this is what
# looks good on iOS).
for size in (192, 512):
    save(f'app/web/icons/Icon-{size}.png', size)
    # Maskable: inset to MASKED_PLATE_FRACTION so the launcher's circular crop
    # does not cut the bubble's tail.
    save(f'app/web/icons/Icon-maskable-{size}.png', size, source=PLATE,
         fill=MASKED_PLATE_FRACTION)
save('app/web/icons/apple-touch-icon.png', 180)
save('app/web/favicon.png', 32, source=PLATE, fill=1.0)

# --- Android ---------------------------------------------------------------
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    # Legacy icons (Android 7 and older) are shown whole, exactly as iOS shows the
    # artwork, so they get the full square with its margin.
    save(f'app/android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
    # The round variant is cropped to a circle, exactly like a maskable icon.
    save(f'app/android/app/src/main/res/mipmap-{density}/ic_launcher_round.png', size,
         source=PLATE, fill=MASKED_PLATE_FRACTION)
# Adaptive icons (Android 8+): a 108dp foreground layer the launcher masks to
# roughly the middle 72dp, over a background layer of one colour. The foreground
# carries the plate and is transparent outside it, so the background colour shows
# as the bubble's outline — the same ring the artwork has.
for density, size in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                      ('xxhdpi', 324), ('xxxhdpi', 432)]:
    save(f'app/android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png',
         size, source=PLATE, fill=MASKED_PLATE_FRACTION, transparent=True)
for name in ('ic_launcher.xml', 'ic_launcher_round.xml'):
    path = root / f'app/android/app/src/main/res/mipmap-anydpi-v26/{name}'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Generated by scripts/generate-icons.py: the launcher masks these two\n'
        '     layers, so the colour never comes from a padding band. -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n')
colors = root / 'app/android/app/src/main/res/values/colors.xml'
colors.write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<!-- Generated by scripts/generate-icons.py from the artwork\'s plate colour. -->\n'
    '<resources>\n'
    f'    <color name="ic_launcher_background">{MARGIN_HEX}</color>\n'
    '</resources>\n')

# --- iOS -------------------------------------------------------------------
# iOS composites the whole square with no mask, so the full artwork is correct.
icons = root / 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
    save(str((icons / entry['filename']).relative_to(root)), size)

print(f'Generated icons (plate {PLATE.size}, plate colour {PLATE_HEX}, '
      f'margin {MARGIN_HEX}, unmasked {PLATE_FRACTION}, masked {MASKED_PLATE_FRACTION})')
