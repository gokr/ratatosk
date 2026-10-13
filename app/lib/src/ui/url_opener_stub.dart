// Opening a URL, on whichever target is being built. Split this way because
// `package:web` only exists for the web target and the app is compiled for all of them.
export 'url_opener_io.dart' if (dart.library.js_interop) 'url_opener_web.dart';
