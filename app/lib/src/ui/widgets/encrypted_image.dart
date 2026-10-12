// Renders an attachment that the server stored as ciphertext.
//
// The normal `Image.network` cannot be used: the bytes on the server are a
// client-side seal, and the key that opens them only exists in the message
// envelope. So the flow is: fetch the blob with the session token, open it with
// the file key, and hand the plaintext bytes to `Image.memory`.
//
// Decrypted bytes are cached per blob id, so scrolling a conversation does not
// re-download and re-decrypt the same picture.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../api/backend.dart';
import '../../crypto/manager.dart';

/// An in-memory cache of decrypted attachments.
///
/// Bounded by count: an attachment is at most a few megabytes and a conversation
/// shows a handful at a time, so an unbounded map would only ever grow.
class AttachmentCache {
  AttachmentCache({this.limit = 24});

  final int limit;
  final Map<String, Uint8List> _bytes = {};
  final Map<String, Future<Uint8List>> _inFlight = {};

  Uint8List? get(String blobId) => _bytes[blobId];

  /// Fetches and decrypts a blob, sharing one request between callers that ask
  /// at the same time (the list rebuilds often).
  Future<Uint8List> load({
    required DecryptedAttachment attachment,
    required String url,
  }) {
    final cached = _bytes[attachment.blobId];
    if (cached != null) return Future.value(cached);
    final pending = _inFlight[attachment.blobId];
    if (pending != null) return pending;

    final future = _fetch(attachment, url).then((bytes) {
      if (_bytes.length >= limit) _bytes.remove(_bytes.keys.first);
      _bytes[attachment.blobId] = bytes;
      _inFlight.remove(attachment.blobId);
      return bytes;
    }).catchError((Object error) {
      _inFlight.remove(attachment.blobId);
      throw error;
    });
    _inFlight[attachment.blobId] = future;
    return future;
  }

  Future<Uint8List> _fetch(DecryptedAttachment attachment, String url) async {
    final sealed = await di<ChatBackend>().fetchBytes(url);
    // A plaintext attachment (a conversation without encryption) is served as
    // it is; a sealed one has a key in the envelope.
    if (attachment.fileKey.isEmpty) return sealed;
    return di<CryptoManager>().openFile(ciphertext: sealed, attachment: attachment);
  }

  void clear() {
    _bytes.clear();
    _inFlight.clear();
  }
}

/// Shows a decrypted image, or a placeholder while it loads.
class EncryptedImage extends StatefulWidget {
  const EncryptedImage({
    super.key,
    required this.attachment,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.onTap,
    this.decodeWidth,
  });

  final DecryptedAttachment attachment;
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  /// Bound for the decoded bitmap, in physical pixels.
  ///
  /// The bytes are a camera's original file, so a thumbnail would otherwise
  /// decode the full-resolution picture (a 12MP photo is roughly a 48MB bitmap)
  /// — which is enough to make a phone fail to draw it at all.
  final int? decodeWidth;

  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant EncryptedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.blobId != widget.attachment.blobId) _start();
  }

  void _start() {
    _bytes = di<AttachmentCache>().load(attachment: widget.attachment, url: widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Placeholder(
            width: widget.width,
            height: widget.height,
            label: 'Cannot decrypt',
            child: const Icon(Icons.lock_outline),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return _Placeholder(
            width: widget.width,
            height: widget.height,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final image = Image.memory(
          bytes,
          fit: widget.fit,
          cacheWidth: widget.decodeWidth,
          // Decryption succeeded but the platform cannot decode the picture
          // (an unusual format, or bytes that decode nowhere). Say so rather
          // than leaving a hole in the conversation.
          errorBuilder: (_, __, ___) => _Placeholder(
            width: widget.width,
            height: widget.height,
            label: 'Cannot display this picture',
            child: const Icon(Icons.broken_image_outlined),
          ),
        );
        return widget.onTap == null
            ? image
            : GestureDetector(onTap: widget.onTap, child: image);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, this.label, required this.child});

  final double? width;
  final double? height;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 160,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label!, style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
