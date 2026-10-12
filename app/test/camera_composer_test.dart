import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ratatosk/src/crypto/crypto.dart';
import 'package:ratatosk/src/crypto/identity.dart';
import 'package:ratatosk/src/crypto/manager.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/chat.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/common.pb.dart';
import 'package:ratatosk/src/gen/ratatosk/v1/keys.pb.dart';
import 'package:ratatosk/src/state/app_state.dart';
import 'package:ratatosk/src/ui/theme.dart';
import 'package:ratatosk/src/ui/widgets/composer.dart';
import 'package:watch_it/watch_it.dart';

import 'fake_backend.dart';

class _Backend extends FakeBackend {
  final uploads = <({Uint8List bytes, bool encrypted})>[];

  @override
  Future<Attachment> uploadAttachment({
    required String filename,
    required String contentType,
    required Uint8List data,
    bool encrypted = false,
  }) {
    uploads.add((bytes: data, encrypted: encrypted));
    return super.uploadAttachment(
      filename: filename,
      contentType: contentType,
      data: data,
      encrypted: encrypted,
    );
  }
}

class _Crypto extends CryptoManager {
  _Crypto(_Backend backend)
    : super(backend: backend, storage: MemoryKeyStorage());
  bool unavailable = false;
  @override
  bool get ready => !unavailable && super.ready;
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWZkAAAAASUVORK5CYII=',
);
/// A captured photo. Two shapes occur in practice and the composer must handle
/// both, so the tests drive both:
///
///   * a path-backed file (native camera): the name is the basename;
///   * a data-backed file (the browser): the name is *empty*.
///
/// The bytes are handed over through `_MemXFile` rather than real file IO:
/// `testWidgets` runs in a fake-async zone where asynchronous file reads inside
/// the widget under test never complete, which hangs the test rather than
/// failing it.
class _MemXFile extends XFile {
  _MemXFile(this._bytes, {String name = '', String mimeType = ''})
      : _name = name,
        super.fromData(Uint8List(0), name: name, mimeType: mimeType);

  final Uint8List _bytes;
  final String _name;

  /// The browser's data-backed files report no name at all, so this cannot rely
  /// on the superclass's value.
  @override
  String get name => _name;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

XFile _nativePhoto() => _MemXFile(_png, name: 'camera.png', mimeType: 'image/png');

/// The browser's shape: a PNG with no filename.
XFile _browserPhoto() => _MemXFile(_png, mimeType: 'image/png');

/// A capture that cannot be read, for the error path.
class _FailingXFile extends XFile {
  _FailingXFile() : super('unreadable.png');

  @override
  Future<Uint8List> readAsBytes() async => throw StateError('unreadable capture');
}

void main() {
  late _Backend backend;
  late _Crypto crypto;
  late AppState state;

  setUp(() async {
    backend = _Backend()..seedConversation();
    crypto = _Crypto(backend);
    state = AppState(backend: backend, crypto: crypto);
    di.registerSingleton<AppState>(state);
    await state.bootstrap(savedToken: 'fake-token');
    final peer = RatatoskCrypto();
    final identity = await peer.newIdentityKeyPair();
    final signing = await peer.newSigningKeyPair();
    backend.addDeviceKey(
      userId: 'u2',
      key: DeviceKey(
        id: 'peer',
        userId: 'u2',
        identityPublicKey: await peer.publicKeyBytes(identity),
        signingPublicKey: await peer.publicKeyBytes(signing),
      ),
    );
    await state.refreshConversationKeys('c1');
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    // Dispose the manager before dropping its registration: it owns the typing
    // and reconnect timers, and a live one outliving the test fails the
    // harness's pending-timer check in whatever test runs next — which reads as
    // an unrelated failure.
    state.dispose();
    await di.reset();
    backend.dispose();
  });

  Future<void> mount(
    WidgetTester tester, {
    Future<XFile?> Function()? capture,
    String conversation = 'c1',
    Message? editing,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: RatatoskTheme.light(),
      home: Scaffold(
        body: Composer(
          conversationId: conversation,
          capturePhoto: capture,
          editing: editing,
          onCancelReply: () {},
          onCancelEdit: () {},
        ),
      ),
    ),
  );

  /// Pumps until the composer has settled.
  ///
  /// It has to outlast the app's typing debounce (two seconds): `enterText`
  /// starts that timer, and a test that ends with it still pending fails the
  /// harness's "no pending timers" invariant — which looks like a camera bug but
  /// is only the test not waiting long enough.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('Enter sends and Shift Enter does not send', (tester) async {
    await mount(tester);
    await tester.enterText(find.byType(TextField), 'send by keyboard');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(backend.sealedSends, hasLength(1));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    await tester.enterText(find.byType(TextField), 'keep drafting');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
    expect(backend.sealedSends, hasLength(1));
  });

  testWidgets('capture previews locally, removal never uploads', (
    tester,
  ) async {
    await mount(tester, capture: () async => _nativePhoto());
    await tester.tap(find.byTooltip('Take a photo'));
    await settle(tester);
    expect(find.byType(Image), findsOneWidget);
    expect(backend.uploads, isEmpty);
    expect(backend.sealedSends, isEmpty);
    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNull);
    expect(backend.uploads, isEmpty);
  });

  testWidgets('only Send seals the captured bytes and message', (tester) async {
    await mount(tester, capture: () async => _nativePhoto());
    await tester.tap(find.byTooltip('Take a photo'));
    await settle(tester);
    expect(backend.uploads, isEmpty);
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    expect(backend.uploads, hasLength(1));
    expect(backend.uploads.single.encrypted, isTrue);
    expect(backend.uploads.single.bytes, isNot(orderedEquals(_png)));
    expect(backend.sentPlaintext, isEmpty);
    expect(backend.sealedSends, hasLength(1));
    expect(find.byType(Image), findsNothing);
    final body = state.bodyOf(state.messages('c1').last);
    expect(body.attachments, hasLength(1));
    expect(body.attachments.single.filename, 'camera.png');
    expect(
      await crypto.openFile(
        ciphertext: backend.uploads.single.bytes,
        attachment: body.attachments.single,
      ),
      orderedEquals(_png),
    );
  });

  testWidgets('a capture with no filename is named, not blank', (tester) async {
    // The browser hands back a data-backed file whose name is empty. The name
    // travels inside the sealed envelope, so a blank one would reach the
    // recipient as an unnamed attachment.
    await mount(tester, capture: () async => _browserPhoto());
    await tester.tap(find.byTooltip('Take a photo'));
    await settle(tester);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    final body = state.bodyOf(state.messages('c1').last);
    expect(body.attachments, hasLength(1));
    expect(body.attachments.single.filename, 'photo.png');
    expect(body.attachments.single.contentType, 'image/png');
  });

  testWidgets('unready crypto refuses attachment before any upload', (
    tester,
  ) async {
    crypto.unavailable = true;
    await state.sendMessageWithFiles(
      'c1',
      text: '',
      files: [(filename: 'camera.png', contentType: 'image/png', bytes: _png)],
    );
    expect(state.lastError, contains('encryption is ready'));
    expect(backend.uploads, isEmpty);
    expect(backend.sealedSends, isEmpty);
    expect(backend.sentPlaintext, isEmpty);
  });

  testWidgets('cancellation preserves text and re-enables camera', (
    tester,
  ) async {
    final result = Completer<XFile?>();
    await mount(tester, capture: () => result.future);
    await tester.enterText(find.byType(TextField), 'draft');
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pump();
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send_rounded)).onPressed, isNull);
    expect(
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.camera_alt_outlined)).onPressed,
      isNull,
    );
    result.complete(null);
    await settle(tester);
    expect(find.text('draft'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.camera_alt_outlined)).onPressed,
      isNotNull,
    );
    expect(backend.uploads, isEmpty);
  });

  testWidgets('permission and read errors are visible and retryable', (
    tester,
  ) async {
    var attempts = 0;
    await mount(
      tester,
      capture: () async {
        if (attempts++ == 0) {
          throw PlatformException(code: 'camera_access_denied');
        }
        return _FailingXFile();
      },
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Take a photo'));
      await settle(tester);
      expect(find.textContaining('Could not take a photo'), findsWidgets);
      expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.camera_alt_outlined)).onPressed,
        isNotNull,
      );
    }
    expect(find.byType(Image), findsNothing);
    expect(backend.uploads, isEmpty);
  });

  testWidgets('away and back invalidates an in-flight camera result', (
    tester,
  ) async {
    final result = Completer<XFile?>();
    Future<XFile?> capture() => result.future;
    await mount(tester, capture: capture);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pump();
    await mount(tester, capture: capture, conversation: 'c2');
    await mount(tester, capture: capture);
    result.complete(_nativePhoto());
    await settle(tester);
    expect(find.byType(Image), findsNothing);
    expect(backend.uploads, isEmpty);
  });

  testWidgets('switching to edit invalidates capture and hides camera', (
    tester,
  ) async {
    final result = Completer<XFile?>();
    Future<XFile?> capture() => result.future;
    await mount(tester, capture: capture);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pump();
    await mount(
      tester,
      capture: capture,
      editing: Message(id: 'edit', text: 'original'),
    );
    result.complete(_nativePhoto());
    await settle(tester);
    expect(find.byTooltip('Take a photo'), findsNothing);
    // Twice by design while editing: the banner and the field both carry the
    // text. What matters is that the draft the camera was capturing is gone.
    expect(find.text('original'), findsNWidgets(2));
    expect(find.text('Editing message'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(backend.uploads, isEmpty);
  });

  testWidgets('late errors after switching drafts are not shown', (
    tester,
  ) async {
    final result = Completer<XFile?>();
    Future<XFile?> capture() => result.future;
    await mount(tester, capture: capture);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pump();
    await mount(tester, capture: capture, conversation: 'c2');
    result.completeError(PlatformException(code: 'camera_access_denied'));
    await settle(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('disposal during capture ignores the result', (tester) async {
    final result = Completer<XFile?>();
    await mount(tester, capture: () => result.future);
    await tester.tap(find.byTooltip('Take a photo'));
    await tester.pumpWidget(const SizedBox());
    result.complete(_nativePhoto());
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(backend.uploads, isEmpty);
  });

  // One test per platform: the override has to be reset before the test ends,
  // and the harness asserts that no foundation debug variable was left changed.
  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ]) {
    final offered = platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
    testWidgets('camera is ${offered ? 'offered' : 'hidden'} on $platform', (
      tester,
    ) async {
      // The override is reset inside the body: the harness checks it before any
      // tearDown runs, so leaving it set fails the test that just used it.
      debugDefaultTargetPlatformOverride = platform;
      try {
        await mount(tester);
        expect(
          find.byTooltip('Take a photo'),
          offered ? findsOneWidget : findsNothing,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
