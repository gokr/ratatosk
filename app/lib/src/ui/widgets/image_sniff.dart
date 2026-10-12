import 'dart:typed_data';

/// Recognises an image from its own bytes.
///
/// The picker is not a reliable source of truth for the type: on Android
/// `image_picker` hands back `XFile(path)` with **no** mime type at all (iOS
/// does set one), and a file selected from the gallery arrives with whatever
/// name the storage provider reported — `IMG_0001.heic` is a photo, but nothing
/// about the name says which. Guessing from the extension therefore classifies
/// a real photo as an opaque attachment, and the UI shows a file icon where the
/// picture should be.
///
/// Sniffing the magic number is authoritative, cheap, and works for a file the
/// user picked from anywhere.
String? sniffImageType(Uint8List bytes) {
  if (bytes.length < 12) return null;

  // JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'image/jpeg';

  // PNG: 89 'P' 'N' 'G' \r \n 1A \n
  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (_startsWith(bytes, png)) return 'image/png';

  // GIF87a / GIF89a
  if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';

  // BMP: 'BM'
  if (_startsWith(bytes, const [0x42, 0x4D])) return 'image/bmp';

  // WebP: 'RIFF' .... 'WEBP'
  if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      _matches(bytes, 8, const [0x57, 0x45, 0x42, 0x50])) {
    return 'image/webp';
  }

  // HEIF/HEIC (what an Android or iOS camera writes when "efficient storage" is
  // on): an ISO-BMFF box 'ftyp' followed by a brand.
  if (_matches(bytes, 4, const [0x66, 0x74, 0x79, 0x70])) {
    const brands = {
      'heic': 'image/heic', 'heix': 'image/heic', 'hevc': 'image/heic',
      'hevx': 'image/heic', 'heim': 'image/heic', 'heis': 'image/heic',
      'mif1': 'image/heif', 'msf1': 'image/heif', 'avif': 'image/avif',
    };
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    final type = brands[brand];
    if (type != null) return type;
  }

  return null;
}

bool _startsWith(Uint8List bytes, List<int> prefix) => _matches(bytes, 0, prefix);

bool _matches(Uint8List bytes, int offset, List<int> pattern) {
  if (bytes.length < offset + pattern.length) return false;
  for (var i = 0; i < pattern.length; i++) {
    if (bytes[offset + i] != pattern[i]) return false;
  }
  return true;
}

/// The content type to record for an attachment: what the bytes actually are
/// when they are recognisable, otherwise what the picker claimed.
String attachmentContentType(Uint8List bytes, String? claimed, String filename) {
  final sniffed = sniffImageType(bytes);
  if (sniffed != null) return sniffed;
  if (claimed != null && claimed.isNotEmpty) return claimed;
  return guessContentType(filename);
}

/// A suffix guess, for when neither the bytes nor the picker say.
String guessContentType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
  return 'application/octet-stream';
}
