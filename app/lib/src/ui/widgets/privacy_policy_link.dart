import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/backend.dart';
import 'package:watch_it/watch_it.dart';

/// The privacy policy the server publishes, as an absolute URL.
///
/// Built from the backend's own origin rather than hard-coded: a self-hosted
/// Ratatosk serves its policy from its own domain, and a link pointing at
/// ratatosk.flatout.works from somebody else's server would be wrong — and would
/// hand a third party a visit from every new user.
Uri privacyPolicyUrl(ChatBackend backend) =>
    backend.baseUrl.resolve('privacy_policy.pdf');

/// Opens the privacy policy in the user's browser.
///
/// Deliberately external rather than an in-app viewer: a policy the user can
/// keep open, bookmark or read later is the point, and the platform's own PDF
/// handling beats anything embedded here. The URL is shown when there is no
/// browser to open, so the link is never a dead end.
Future<void> openPrivacyPolicy(BuildContext context) async {
  final url = privacyPolicyUrl(di<ChatBackend>());
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) throw StateError('no browser accepted the URL');
  } catch (error) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not open the privacy policy. It is at $url')),
    );
  }
}

/// A quiet text button for the sign-in screen and settings.
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => openPrivacyPolicy(context),
      child: Text(
        'Privacy policy',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
