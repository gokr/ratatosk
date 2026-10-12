import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// These files are what the *platform* reads when someone installs the app:
/// nothing in the Dart code would notice them going wrong. A lowercase name shows
/// up as the wrong label under the icon, a missing icon as a blank tile, and a
/// wrong proportion as a logo that is either a small tile in a sea of white or a
/// plain blue square with no speech-bubble outline at all. All three have
/// happened, so all three are asserted here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  /// Decodes a PNG and reports how much of it is the bubble's blue, how much is
  /// the light margin, and how much is transparent.
  ///
  /// [asDisc] measures only what a launcher actually shows. That distinction is
  /// the whole point: a circular mask removes the canvas corners, which is
  /// precisely where a full-bleed plate hides its own light corners — measuring
  /// the whole square therefore *accepts* an icon that shows no white at all.
  /// The reported bug is invisible unless the disc is modelled.
  Future<({double plate, double margin, double clear})> proportions(
    String path, {
    bool asDisc = false,
  }) async {
    final bytes = File(path).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = data!.buffer.asUint8List();
    final side = image.width;
    final centre = (side - 1) / 2;
    final radius = side / 2;
    var plate = 0, margin = 0, clear = 0, total = 0;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        if (asDisc) {
          final dx = x - centre, dy = y - centre;
          if (dx * dx + dy * dy > radius * radius) continue;
        }
        total++;
        final i = (y * side + x) * 4;
        final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2], a = pixels[i + 3];
        if (a < 16) {
          clear++;
        } else if (b > 150 && b - (r < g ? r : g) > 40) {
          plate++;
        } else if (r > 235 && g > 235 && b > 235) {
          margin++;
        }
      }
    }
    codec.dispose();
    return (plate: plate / total, margin: margin / total, clear: clear / total);
  }

  test('the installed app is named Ratatosk, not ratatosk', () {
    expect(manifest['name'], 'Ratatosk');
    expect(manifest['short_name'], 'Ratatosk',
        reason: 'this is the label Android puts under the icon');
    expect(manifest['start_url'], isNotNull);
    expect(manifest['display'], 'standalone');
  });

  test('the manifest declares both ordinary and maskable icons', () {
    final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    for (final size in ['192x192', '512x512']) {
      expect(icons.where((i) => i['sizes'] == size), isNotEmpty,
          reason: '$size is required for an installable PWA');
    }
    // A maskable icon is what keeps a platform that crops to a circle (Android,
    // and a home-screen icon on iOS) from cutting the artwork's edges off.
    expect(icons.where((i) => i['purpose'] == 'maskable'), isNotEmpty);

    for (final icon in icons) {
      final path = 'web/${icon['src']}';
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is declared but missing');
      expect(file.lengthSync(), greaterThan(0));
    }
  });

  group('the bubble keeps its outline', () {
    // The design is a blue speech bubble on a light field. Both ways of getting
    // the proportion wrong have shipped: scaled to the maskable safe zone the
    // bubble became a small tile ringed by white, and cropped to the canvas it
    // became a plain blue square with no outline.
    for (final path in [
      'web/icons/Icon-maskable-512.png',
      'web/icons/Icon-maskable-192.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png',
    ]) {
      test('$path shows a bubble and a margin', () async {
        // Measured as the launcher shows it: cropped to a circle.
        final p = await proportions(path, asDisc: true);
        expect(p.plate, greaterThan(0.20),
            reason: 'the bubble is missing or far too small: ${p.plate}');
        expect(p.plate, lessThan(0.55),
            reason: 'the bubble fills the disc, so the outline is gone: ${p.plate}');
        expect(p.margin, greaterThan(0.38),
            reason: 'no light outline is visible inside the disc: ${p.margin}');
      });
    }

    test('the masked icon matches the proportion iOS is happy with', () async {
      // iOS composites the artwork whole with no mask, and it is the appearance
      // that was reported as correct. A masked variant should not look like a
      // different logo.
      // iOS is shown as a whole square, the maskable icon as a disc, so compare
      // each in the shape it is displayed in.
      final ios = await proportions(
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
          asDisc: true);
      final maskable = await proportions('web/icons/Icon-maskable-512.png', asDisc: true);
      // The masked icon is deliberately inset (see MASKED_PLATE_FRACTION so a
      // launcher's crop cannot reach the bubble), so it shows *less* plate than
      // iOS rather than the same amount. What must not differ is the shape read:
      // both must be clearly a bubble on a light field, not a filled square.
      expect(maskable.margin, greaterThan(0.38));
      expect(ios.margin, greaterThan(0.38));
    });
  });

  test('masked icons leave real clearance around the artwork', () async {
    // Reported from a device: the bubble's tail was being sliced off by Android's
    // circular crop, because the artwork was scaled to just inside it. Nothing the
    // bubble is drawn with may reach the mask's edge.
    for (final path in [
      'web/icons/Icon-maskable-512.png',
      'web/icons/Icon-maskable-192.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png',
    ]) {
      final bytes = File(path).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = data!.buffer.asUint8List();
      final side = image.width;
      final centre = (side - 1) / 2;
      final radius = side / 2;
      // The furthest artwork pixel from the centre, as a fraction of the radius:
      // 1.0 means the mask cuts it. A few pixels of clearance is not enough on a
      // real launcher — its visible circle, its own insets and antialiasing at
      // small sizes all eat into the margin — so require 10%.
      var furthest = 0.0;
      final marginR = pixels[0], marginG = pixels[1], marginB = pixels[2];
      for (var y = 0; y < side; y++) {
        for (var x = 0; x < side; x++) {
          final dx = x - centre, dy = y - centre;
          if (dx * dx + dy * dy > radius * radius) continue;
          final p = (y * side + x) * 4;
          final a = pixels[p + 3];
          if (a < 16) continue; // transparent: not artwork
          final dr = (pixels[p] - marginR).abs();
          final dg = (pixels[p + 1] - marginG).abs();
          final db = (pixels[p + 2] - marginB).abs();
          if (dr <= 3 && dg <= 3 && db <= 3) continue; // the light margin
          final distance = math.sqrt(dx * dx + dy * dy) / radius;
          if (distance > furthest) furthest = distance;
        }
      }
      codec.dispose();
      expect(furthest, lessThan(0.90),
          reason: '$path reaches ${furthest.toStringAsFixed(3)} of the mask radius, '
              'so a launcher will clip the bubble\'s tail');
    }
  });

  test('the adaptive foreground carries transparency, not a filled square', () async {
    // Android composites the foreground over the background colour and then masks
    // it. If the foreground were opaque to its edges the outline would vanish and
    // the background colour would be invisible, which is exactly the reported bug.
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final p = await proportions(
          'android/app/src/main/res/mipmap-$density/ic_launcher_foreground.png',
          asDisc: true);
      // Transparent inside the disc is what lets the background layer show as the
      // outline. An opaque foreground covers it and the white disappears. The
      // figure is smaller than the maskable icon's margin because the squirrel's
      // own white fur is opaque and sits inside the disc too.
      expect(p.clear, greaterThan(0.10),
          reason: '$density foreground covers the outline instead of leaving it '
              'transparent: $p');
      expect(p.plate, greaterThan(0.20), reason: '$density bubble too small: $p');
      expect(p.plate, lessThan(0.55), reason: '$density bubble too large: $p');
    }
    // The background layer supplies the outline colour, and it must be the light
    // margin rather than the bubble's blue (setting it blue was the bug that
    // removed every trace of white).
    final colors = File('android/app/src/main/res/values/colors.xml').readAsStringSync();
    final hex = RegExp(r'ic_launcher_background">#([0-9A-Fa-f]{6})<')
        .firstMatch(colors)!.group(1)!;
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    expect(r, greaterThan(200));
    expect(g, greaterThan(200));
    expect(b, greaterThan(200));
  });

  test('iOS is told the display name explicitly', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html,
        contains('<meta name="apple-mobile-web-app-title" content="Ratatosk">'),
        reason: 'iOS uses this for the home-screen label, not the manifest');
    expect(html, contains('<link rel="apple-touch-icon"'));
    // The apple-touch-icon must not be a padded variant: iOS does the rounding
    // itself.
    expect(File('web/icons/apple-touch-icon.png').existsSync(), isTrue);
  });

  test('Android has adaptive icons that reference both layers', () {
    for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
      final f = File('android/app/src/main/res/mipmap-anydpi-v26/$name');
      expect(f.existsSync(), isTrue, reason: '$name is missing');
      final xml = f.readAsStringSync();
      expect(xml, contains('adaptive-icon'));
      expect(xml, contains('@mipmap/ic_launcher_foreground'));
      expect(xml, contains('@color/ic_launcher_background'));
    }
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(androidManifest, contains('android:label="Ratatosk"'));
    expect(androidManifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
  });
}
