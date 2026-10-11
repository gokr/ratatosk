import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Renders a QR code.
///
/// The encoding comes from `package:qr` (pure Dart) and the painting is done
/// here rather than through a widget wrapper package: it is forty lines, it
/// keeps the quiet zone and the colours under our control, and it avoids a
/// dependency on a plugin that has to track Flutter releases.
///
/// Error correction is set to `medium` (the usual 15% recovery): an invitation
/// link shown on a phone gets scanned off a screen at an angle, in a cafe, by a
/// camera with a fingerprint on it.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    this.size = 200,
    this.foreground,
    this.background,
    this.semanticLabel,
  });

  /// What the code carries. For an invitation this is the full link, so any
  /// scanner — including the camera app on a phone that has never heard of
  /// Ratatosk — does the right thing.
  final String data;
  final double size;
  final Color? foreground;
  final Color? background;

  /// Screen-reader text. A QR code is a picture of a link, so the link itself
  /// is the useful description.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qr = QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.medium,
    );
    return Semantics(
      label: semanticLabel ?? data,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _QrPainter(
            QrImage(qr),
            foreground: foreground ?? scheme.onSurface,
            background: background ?? Colors.white,
          ),
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image, {required this.foreground, required this.background});

  final QrImage image;
  final Color foreground;
  final Color background;

  /// A QR code needs a quiet zone around it to be read reliably: without it a
  /// scanner cannot find the finder patterns against a busy background. Four
  /// modules is the specification's minimum.
  static const _quietZoneModules = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final total = image.moduleCount + _quietZoneModules * 2;
    final module = size.width / total;

    final backgroundPaint = Paint()..color = background;
    final rect = Offset.zero & size;

    // The code sits on its own light plate, so it stays scannable whatever the
    // app's theme is doing behind it.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(module * 2)),
      backgroundPaint,
    );

    final paint = Paint()..color = foreground..style = PaintingStyle.fill;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (col + _quietZoneModules) * module,
            (row + _quietZoneModules) * module,
            // A hair more than one module: seams between adjacent rectangles
            // show up as light lines that scanners can trip on.
            module + 0.5,
            module + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.image != image || old.foreground != foreground || old.background != background;
}
