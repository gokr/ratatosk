// The message body that travels inside the ciphertext.
//
// Everything a reader needs is in here: the text, the attachments (with their
// real filenames, types and the file keys that open them) and the quoted reply.
// The server sees one opaque blob and a blob id per attachment.
//
// The encoding is a compact hand-written one rather than protobuf, so the app
// does not need a second code generator for a type that only ever exists
// between two clients. The format is versioned by the leading byte; a reader
// that does not know a version says so instead of guessing.
import 'dart:convert';
import 'dart:typed_data';

import 'crypto.dart';

/// The current envelope format version.
const messageContentVersion = 1;

/// An attachment as the sender's device describes it.
class EncryptedAttachment {
  const EncryptedAttachment({
    required this.blobId,
    required this.fileKey,
    required this.nonce,
    required this.filename,
    required this.contentType,
    required this.size,
  });

  /// The server-side blob that holds the sealed bytes.
  final String blobId;

  /// The 32-byte key that opens the blob. It only ever exists inside this
  /// envelope, which is itself sealed — that is what keeps the server from
  /// reading the file it is storing.
  final Uint8List fileKey;
  final Uint8List nonce;

  /// The real filename and type. The server stored neither.
  final String filename;
  final String contentType;

  /// The plaintext size, for a progress indicator that means something.
  final int size;

  bool get isImage => contentType.startsWith('image/');

  Map<String, dynamic> toJson() => {
        'blob': blobId,
        'key': base64Encode(fileKey),
        'nonce': base64Encode(nonce),
        'name': filename,
        'type': contentType,
        'size': size,
      };

  static EncryptedAttachment fromJson(Map<String, dynamic> json) => EncryptedAttachment(
        blobId: json['blob'] as String? ?? '',
        fileKey: _bytes(json['key']),
        nonce: _bytes(json['nonce']),
        filename: json['name'] as String? ?? 'file',
        contentType: json['type'] as String? ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );

  static Uint8List _bytes(Object? value) =>
      value is String ? base64Decode(value) : Uint8List(0);
}

/// The quoted parent of a reply.
class ReplyQuote {
  const ReplyQuote({required this.messageId, required this.text});

  final String messageId;
  final String text;

  Map<String, dynamic> toJson() => {'id': messageId, 'text': text};

  static ReplyQuote fromJson(Map<String, dynamic> json) => ReplyQuote(
        messageId: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}

/// The plaintext of one message.
class MessageContent {
  const MessageContent({
    this.text = '',
    this.attachments = const [],
    this.replyTo,
  });

  final String text;
  final List<EncryptedAttachment> attachments;
  final ReplyQuote? replyTo;

  bool get isEmpty => text.trim().isEmpty && attachments.isEmpty;

  /// Serializes to the bytes that get sealed.
  ///
  /// Layout: one version byte, then a JSON document in UTF-8. JSON keeps the
  /// format debuggable and forward-compatible (unknown keys are ignored), at
  /// the cost of a few bytes that the AEAD padding-free design already accepts.
  Uint8List encode() {
    final payload = jsonEncode({
      't': text,
      if (attachments.isNotEmpty) 'a': attachments.map((a) => a.toJson()).toList(),
      if (replyTo != null) 'r': replyTo!.toJson(),
    });
    return Uint8List.fromList([messageContentVersion, ...utf8.encode(payload)]);
  }

  /// Parses sealed plaintext. Throws [CryptoFailure] when the version is
  /// unknown, so an old client reports a new message as unreadable rather than
  /// showing garbage.
  static MessageContent decode(List<int> bytes) {
    if (bytes.isEmpty) throw CryptoFailure('the message body is empty');
    final version = bytes.first;
    if (version != messageContentVersion) {
      throw CryptoFailure('this message uses a newer format (v$version) than this app understands');
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(bytes.sublist(1))) as Map<String, dynamic>;
    } catch (error) {
      throw CryptoFailure('the message body could not be parsed', cause: error);
    }
    return MessageContent(
      text: json['t'] as String? ?? '',
      attachments: (json['a'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EncryptedAttachment.fromJson)
          .toList(),
      replyTo: json['r'] is Map<String, dynamic>
          ? ReplyQuote.fromJson(json['r'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Seals a file for upload, and opens one that came in.
///
/// Files get their own random key rather than the conversation key, so the same
/// file can be re-sent to a different conversation without re-encrypting it, and
/// so a leaked file key exposes exactly one file.
class FileCipher {
  FileCipher(this.crypto);

  final RatatoskCrypto crypto;

  /// Encrypts [data] under a fresh key. The key travels in the message
  /// envelope; the ciphertext is what the server stores.
  Future<({Uint8List ciphertext, Uint8List key, Uint8List nonce})> seal(Uint8List data) async {
    final key = await crypto.randomBytes(symmetricKeyBytes);
    final sealed = await crypto.seal(
      key: key,
      plaintext: data,
      aad: '$cryptoVersion/file',
    );
    return (ciphertext: sealed.combined, key: key, nonce: sealed.nonce);
  }

  /// Decrypts bytes fetched from the server.
  Future<Uint8List> open({
    required List<int> ciphertext,
    required List<int> key,
    required List<int> nonce,
  }) =>
      crypto.unseal(
        key: key,
        sealed: Sealed.fromCombined(ciphertext, nonce),
        aad: '$cryptoVersion/file',
      );
}
