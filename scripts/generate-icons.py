#!/usr/bin/env python3
"""Regenerate committed launcher assets from the supplied artwork (Pillow)."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / 'Blue Squirrel Messenger Icon.png'
image = Image.open(source).convert('RGB')

def save(path, size, padded=False):
    path = root / path
    path.parent.mkdir(parents=True, exist_ok=True)
    if padded:
        # The central 80% is the maskable safe zone's diameter. Fit a square
        # inside that circle, leaving the entire supplied artwork uncropped.
        inner = round(size * 0.56)
        out = Image.new('RGB', (size, size), image.getpixel((0, 0)))
        out.paste(image.resize((inner, inner), Image.Resampling.LANCZOS),
                  ((size-inner)//2, (size-inner)//2))
    else:
        out = image.resize((size, size), Image.Resampling.LANCZOS)
    out.save(path)

save('app/assets/brand/logo.png', 512)
for size in (192, 512):
    save(f'app/web/icons/Icon-{size}.png', size)
    save(f'app/web/icons/Icon-maskable-{size}.png', size, padded=True)
save('app/web/icons/apple-touch-icon.png', 180)
save('app/web/favicon.png', 32)
for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save(f'app/android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
    save(f'app/android/app/src/main/res/mipmap-{density}/ic_launcher_round.png', size, padded=True)
icons = root / 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset'
for entry in json.loads((icons/'Contents.json').read_text())['images']:
    size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
    save(str((icons/entry['filename']).relative_to(root)), size)
print('Generated in-app, web, Android and iOS icons')
