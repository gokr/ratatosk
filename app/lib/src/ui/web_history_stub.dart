// Replacing the browser's history entry without a navigation. Split from the web
// implementation because `package:web` only exists on the web target, and main.dart
// is compiled for every platform.
export 'web_history_io.dart' if (dart.library.js_interop) 'web_history_web.dart';
