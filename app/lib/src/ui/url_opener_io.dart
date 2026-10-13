import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in whatever browser the platform has.
///
/// Returns false when there is none, so a caller can say so rather than leaving a
/// button that appears to do nothing.
Future<bool> openExternalUrl(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
