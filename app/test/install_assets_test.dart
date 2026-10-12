import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// These files are what the *platform* reads when someone installs the app, and
/// nothing in the Dart code would notice them going wrong: a lowercase or
/// mismatched name shows up as the wrong label under the home-screen icon, and a
/// missing icon as a blank tile. So they are asserted here.
void main() {
  final manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

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

  test('iOS is told the display name explicitly', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html,
        contains('<meta name="apple-mobile-web-app-title" content="Ratatosk">'),
        reason: 'iOS uses this for the home-screen label, not the manifest');
    expect(html, contains('<link rel="apple-touch-icon"'));
    // The apple-touch-icon must not be a maskable/padded variant: iOS does the
    // rounding itself.
    expect(File('web/icons/apple-touch-icon.png').existsSync(), isTrue);
  });

  test('Android has adaptive icons, so the mask never exposes padding', () {
    // Without an adaptive icon Android 8+ wraps the legacy bitmap in a shape of
    // its own choosing, which is what leaves a band of background around a small
    // logo on the round variant.
    for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
      final f = File('android/app/src/main/res/mipmap-anydpi-v26/$name');
      expect(f.existsSync(), isTrue, reason: '$name is missing');
      final xml = f.readAsStringSync();
      expect(xml, contains('adaptive-icon'));
      expect(xml, contains('@mipmap/ic_launcher_foreground'));
      expect(xml, contains('@color/ic_launcher_background'));
    }
    final colors = File('android/app/src/main/res/values/colors.xml').readAsStringSync();
    expect(colors, contains('ic_launcher_background'));
    // The launcher label, which comes from the manifest rather than the code.
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(androidManifest, contains('android:label="Ratatosk"'));
    expect(androidManifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));
  });
}
