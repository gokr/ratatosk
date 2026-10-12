import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/ui/widgets/brand_logo.dart';

void main() {
  testWidgets('brand artwork loads from bundled asset at the requested size', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
        body: BrandLogo(size: 96))));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/brand/logo.png');
    expect(tester.getSize(find.byType(Image)), const Size(96, 96));
    expect(image.semanticLabel, 'Ratatosk squirrel logo');
    expect(tester.takeException(), isNull);
  });
}
