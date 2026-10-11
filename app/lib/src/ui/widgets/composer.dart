import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_it/watch_it.dart';

import '../../api/backend.dart';
import '../../gen/ratatosk/v1/chat.pb.dart';
import '../../state/app_state.dart';
import '../theme.dart';

/// The message composer: type, attach, send.
///
/// It also owns the two things that are awkward to get right elsewhere:
/// announcing "typing" without spamming the server (the state layer rate-limits
/// that), and attaching files without blocking the UI on the upload.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.conversationId,
    this.replyTo,
    this.editing,
    required this.onCancelReply,
    required this.onCancelEdit,
    this.capturePhoto,
  });

  final String conversationId;

  /// Optional camera seam for tests or a platform-specific capture provider.
  final Future<XFile?> Function()? capturePhoto;

  /// The message being replied to, shown as a banner above the field.
  final Message? replyTo;

  /// The message being edited; when set, sending rewrites it.
  final Message? editing;

  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// Picked files, held in memory until the message is sent: sealing and
  /// uploading happens on send, so a cancelled attachment costs nothing.
  final List<AttachmentUpload> _pending = [];
  bool _uploading = false;
  int _draftGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _controller.text = widget.editing!.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(covariant Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching to a different conversation must not carry a draft across.
    if (oldWidget.conversationId != widget.conversationId ||
        oldWidget.editing?.id != widget.editing?.id) {
      // Invalidate in-flight pickers even when switching away and back.
      _draftGeneration++;
      _controller.clear();
      _pending.clear();
    }
    if (widget.editing != null && oldWidget.editing?.id != widget.editing?.id) {
      _controller.text = widget.editing!.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _controller.text.trim().isNotEmpty || _pending.isNotEmpty;

  Future<void> _pickAttachments() async {
    if (_uploading) return;
    final generation = _draftGeneration;
    setState(() => _uploading = true);
    try {
      final files = await openFiles();
      for (final file in files) {
        try {
          final bytes = await file.readAsBytes();
          if (!mounted || generation != _draftGeneration) return;
          setState(
            () => _pending.add((
              filename: file.name,
              contentType: file.mimeType ?? _guessContentType(file.name),
              bytes: bytes,
            )),
          );
        } catch (error) {
          _showPickerError(generation, 'Could not read ${file.name}', error);
        }
      }
    } catch (error) {
      _showPickerError(generation, 'Could not attach a file', error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPickerError(int generation, String message, Object error) {
    if (!mounted || generation != _draftGeneration) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message: ${describeError(error)}')),
    );
  }

  bool get _cameraSupported =>
      widget.capturePhoto != null ||
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _takePhoto() async {
    if (_uploading || widget.editing != null) return;
    final generation = _draftGeneration;
    setState(() => _uploading = true);
    try {
      final photo =
          await (widget.capturePhoto?.call() ??
              // On web this uses the browser's capture hint; unsupported browsers
              // fall back to choosing an image. Do not request unrelated metadata.
              ImagePicker().pickImage(
                source: ImageSource.camera,
                requestFullMetadata: false,
              ));
      if (photo == null) return; // Cancelled or no camera available.
      final bytes = await photo.readAsBytes();
      if (!mounted || generation != _draftGeneration) return;
      setState(
        () => _pending.add((
          filename: photoFilename(photo),
          contentType:
              photo.mimeType ?? _guessContentType(photoFilename(photo)),
          bytes: bytes,
        )),
      );
    } catch (error) {
      _showPickerError(generation, 'Could not take a photo', error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// A filename for a captured photo.
  ///
  /// A camera capture does not always come with one: a path-backed file gives
  /// its basename, but the browser hands back a data-backed file whose name is
  /// empty. The name travels inside the sealed envelope, so it must not be
  /// blank — derive one from the type the picker did report.
  @visibleForTesting
  static String photoFilename(XFile photo) {
    final name = photo.name.trim();
    if (name.isNotEmpty) return name;
    switch (photo.mimeType) {
      case 'image/png':
        return 'photo.png';
      case 'image/webp':
        return 'photo.webp';
      case 'image/gif':
        return 'photo.gif';
      default:
        return 'photo.jpg';
    }
  }

  /// file_selector leaves the MIME type empty on some platforms; the server
  /// only uses it to decide between inline and download, so a suffix guess is
  /// enough.
  static String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.txt') || lower.endsWith('.md')) return 'text/plain';
    return 'application/octet-stream';
  }

  Future<void> _send() async {
    if (_uploading) return;
    final state = di<AppState>();
    final text = _controller.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;

    if (widget.editing != null) {
      await state.editMessage(widget.conversationId, widget.editing!.id, text);
      widget.onCancelEdit();
      _controller.clear();
      return;
    }

    final files = List<AttachmentUpload>.from(_pending);
    final replyTo = widget.replyTo?.id;
    _controller.clear();
    setState(() => _pending.clear());
    widget.onCancelReply();
    state.stopTyping(widget.conversationId);
    // Sealing and uploading happen inside the manager, so the composer never
    // handles key material.
    await state.sendMessageWithFiles(
      widget.conversationId,
      text: text,
      files: files,
      replyToId: replyTo,
    );
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RatatoskTheme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.editing != null)
              _ContextBanner(
                icon: Icons.edit_outlined,
                title: 'Editing message',
                body: widget.editing!.text,
                onCancel: () {
                  widget.onCancelEdit();
                  _controller.clear();
                },
              )
            else if (widget.replyTo != null)
              _ContextBanner(
                icon: Icons.reply,
                title: 'Replying to',
                body:
                    widget.replyTo!.deleted
                        ? 'Deleted message'
                        : widget.replyTo!.text,
                onCancel: widget.onCancelReply,
              ),
            if (_pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pending.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final file = _pending[index];
                      final isImage = file.contentType.startsWith('image/');
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            // The bytes are local, so the preview needs no
                            // upload and no key: it renders from memory.
                            child:
                                isImage
                                    ? Image.memory(
                                      file.bytes,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.insert_drive_file_outlined,
                                    ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: IconButton(
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove',
                              onPressed:
                                  () =>
                                      setState(() => _pending.removeAt(index)),
                              icon: CircleAvatar(
                                radius: 11,
                                backgroundColor: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.close,
                                  size: 13,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _uploading ? null : _pickAttachments,
                  tooltip: 'Attach a file',
                  icon:
                      _uploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.add_circle_outline),
                ),
                if (_cameraSupported && widget.editing == null)
                  IconButton(
                    onPressed: _uploading ? null : _takePhoto,
                    tooltip: 'Take a photo',
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        di<AppState>().stopTyping(widget.conversationId);
                      } else {
                        di<AppState>().notifyTyping(widget.conversationId);
                      }
                      setState(() {});
                    },
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Aa'),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  onPressed: !_uploading && _canSend ? _send : null,
                  tooltip: widget.editing != null ? 'Save' : 'Send',
                  icon: Icon(
                    widget.editing != null ? Icons.check : Icons.send_rounded,
                  ),
                ),
              ],
            ),
            if (_pending.isEmpty &&
                _controller.text.isEmpty &&
                widget.editing == null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  'Enter to send · long-press a message to react',
                  style: TextStyle(fontSize: 10, color: colors.timestamp),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The banner that shows what is being replied to or edited.
class _ContextBanner extends StatelessWidget {
  const _ContextBanner({
    required this.icon,
    required this.title,
    required this.body,
    required this.onCancel,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(
                  body.isEmpty ? 'Attachment' : body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
