import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ratatosk/src/ui/widgets/image_sniff.dart';

Uint8List _bytes(List<int> head, {int length = 32}) {
  final out = Uint8List(length);
  for (var i = 0; i < head.length; i++) {
    out[i] = head[i];
  }
  return out;
}

/// A HEIC file: an ISO-BMFF 'ftyp' box whose brand follows at offset 8.
Uint8List _heic(String brand) {
  final out = Uint8List(32);
  out.setAll(4, 'ftyp'.codeUnits);
  out.setAll(8, brand.codeUnits);
  return out;
}

void main() {
  test('recognises the formats a phone actually produces', () {
    expect(sniffImageType(_bytes([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(sniffImageType(_bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])),
        'image/png');
    expect(sniffImageType(_bytes('GIF89a'.codeUnits)), 'image/gif');
    expect(sniffImageType(_bytes('BM'.codeUnits)), 'image/bmp');
    final webp = Uint8List(16)
      ..setAll(0, 'RIFF'.codeUnits)
      ..setAll(8, 'WEBP'.codeUnits);
    expect(sniffImageType(webp), 'image/webp');
    expect(sniffImageType(_heic('heic')), 'image/heic');
    expect(sniffImageType(_heic('mif1')), 'image/heif');
  });

  test('does not call a document a picture', () {
    expect(sniffImageType(_bytes('%PDF-1.7'.codeUnits)), isNull);
    expect(sniffImageType(_bytes('hello, this is a text file'.codeUnits)), isNull);
    expect(sniffImageType(Uint8List(4)), isNull);
    expect(sniffImageType(Uint8List(0)), isNull);
  });

  group('the content type recorded for an attachment', () {
    test('comes from the bytes when the picker says nothing', () {
      // The Android case: image_picker returns XFile(path) with no mime type at
      // all, and a gallery file may be named anything. The bytes are the only
      // trustworthy evidence, and getting this wrong is what showed a file icon
      // where the photo should have been.
      expect(
        attachmentContentType(_heic('heic'), null, 'IMG_20260101_120000.heic'),
        'image/heic',
      );
      expect(
        attachmentContentType(_heic('heic'), null, 'photo'),
        'image/heic',
        reason: 'a name with no extension must not decide anything',
      );
      expect(
        attachmentContentType(_bytes([0xFF, 0xD8, 0xFF, 0xE0]), null, 'no-extension'),
        'image/jpeg',
      );
    });

    test('trusts the bytes over a wrong claim', () {
      // A camera that writes JPEG under a .heic name (or a picker that guesses
      // from the extension) must not be believed.
      expect(
        attachmentContentType(_bytes([0xFF, 0xD8, 0xFF, 0xE0]), 'image/heic', 'x.heic'),
        'image/jpeg',
      );
    });

    test('falls back to the claim, then the suffix, for non-pictures', () {
      expect(attachmentContentType(_bytes('%PDF-1.7'.codeUnits), 'application/pdf', 'a.pdf'),
          'application/pdf');
      expect(attachmentContentType(_bytes('%PDF-1.7'.codeUnits), null, 'a.pdf'),
          'application/pdf');
      expect(attachmentContentType(_bytes('%PDF-1.7'.codeUnits), null, 'a'), 
          'application/octet-stream');
      expect(attachmentContentType(_bytes('%PDF-1.7'.codeUnits), '', 'notes.md'),
          'text/plain');
    });
  });
}
