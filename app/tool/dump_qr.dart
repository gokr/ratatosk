// Print the module matrix of a QR code, so the render in a screenshot can be
// checked against the encoder's own output.
//
//   dart run tool/dump_qr.dart 'http://example/join/abc'
//
// ignore_for_file: avoid_print
import 'package:qr/qr.dart';

void main(List<String> args) {
  final data = args.isEmpty ? 'hello' : args.first;
  final code = QrCode(
    payload: QrPayload.fromString(data),
    errorCorrectLevel: QrErrorCorrectLevel.medium,
  );
  final image = QrImage(code);
  print('moduleCount=${image.moduleCount}');
  final rows = <String>[];
  for (var r = 0; r < image.moduleCount; r++) {
    final row = StringBuffer();
    for (var c = 0; c < image.moduleCount; c++) {
      row.write(image.isDark(r, c) ? '1' : '0');
    }
    rows.add(row.toString());
  }
  print(rows.join('\n'));
}
