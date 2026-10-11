import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import '../api/backend.dart';
import '../crypto/manager.dart';
import '../gen/ratatosk/v1/keys.pb.dart';
import '../state/app_state.dart';
import 'theme.dart';
import 'widgets/avatar.dart';

/// The encryption panel of a conversation: which keys this device would encrypt
/// to, and the safety number to compare out of band.
///
/// This is the screen that turns end-to-end encryption from a claim into
/// something a user can check. The server hands out public keys, so a malicious
/// one could substitute its own; comparing the safety number over a channel the
/// server does not control is what rules that out (docs/E2EE.md §6).
Future<void> showEncryptionSheet(BuildContext context, String conversationId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => EncryptionSheet(conversationId: conversationId),
  );
}

class EncryptionSheet extends StatefulWidget {
  const EncryptionSheet({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<EncryptionSheet> createState() => _EncryptionSheetState();
}

class _EncryptionSheetState extends State<EncryptionSheet> {
  List<DeviceKey> _keys = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = di<AppState>();
    final conversation = state.conversation(widget.conversationId);
    if (conversation == null) {
      setState(() {
        _loading = false;
        _error = 'This conversation is gone.';
      });
      return;
    }
    final others = conversation.members.map((m) => m.user.id).where((id) => id != state.me?.id).toList();
    try {
      final keys = await di<ChatBackend>().listDeviceKeys(others);
      if (!mounted) return;
      setState(() {
        _keys = keys;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load keys: $error';
      });
    }
  }

  /// Whether this conversation is a group. Groups distribute a sender key to
  /// every device of every member, so the multi-device notice does not apply.
  bool get _isGroup => di<AppState>().conversation(widget.conversationId)?.kind == 'group';

  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();

    final conversation = state.conversation(widget.conversationId);
    final missingPeer =
        conversation == null ? null : di<CryptoManager>().peerWithoutKey(conversation);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Icon(
                missingPeer == null ? Icons.lock : Icons.lock_open_outlined,
                color: missingPeer == null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Encryption',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Messages are sealed on this device. The server stores ciphertext it cannot read.',
            style: TextStyle(color: RatatoskTheme.of(context).timestamp),
          ),
          const SizedBox(height: 16),
          if (missingPeer != null)
            _Notice(
              icon: Icons.error_outline,
              text: '$missingPeer has no encryption keys yet, so a message cannot be sealed for them. '
                  'Sending is refused rather than quietly sent in the clear. They need to sign in '
                  'with the app once.',
            )
          else if (!state.encryptionReady)
            _Notice(
              icon: Icons.warning_amber_rounded,
              text: 'This device has no encryption keys yet, so messages are sent unencrypted.',
            )
          else
            _KeyRow(
              label: 'This device',
              detail: state.ownFingerprint,
              deviceLabel: 'You',
              isSelf: true,
            ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_error != null)
            _Notice(icon: Icons.error_outline, text: _error!)
          else if (_keys.isEmpty)
            const _Notice(icon: Icons.person_search, text: 'No keys found for the other participants yet.')
          else ...[
            if (_keys.length > 1 && !_isGroup)
              _Notice(
                icon: Icons.devices_other,
                text: 'This contact has ${_keys.length} devices. A direct conversation is '
                    'encrypted to their first device only, so the others will not be able to '
                    'read it yet (docs/E2EE.md §1).',
              ),
            Text('Keys in this conversation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ..._keys.map((key) => _KeyRow(
                  label: key.label.isEmpty ? key.platform : key.label,
                  detail: key.fingerprint,
                  deviceLabel: key.revoked ? 'revoked' : '',
                )),
            const SizedBox(height: 16),
            Text('Safety number', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Compare this with the other person over a call or in person. If it matches on both '
              'sides, no one is between you — including the server.',
              style: TextStyle(color: RatatoskTheme.of(context).timestamp, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _SafetyNumbers(peerKeys: _keys),
            const SizedBox(height: 8),
            _VerificationRow(conversationId: widget.conversationId, peerKeys: _keys),
          ],
          const SizedBox(height: 24),
          Text(
            'Read what this does and does not protect: docs/E2EE.md',
            style: TextStyle(fontSize: 11, color: RatatoskTheme.of(context).timestamp),
          ),
        ],
      ),
    );
  }
}

/// One safety number per peer device, computed locally.
class _SafetyNumbers extends StatefulWidget {
  const _SafetyNumbers({required this.peerKeys});

  final List<DeviceKey> peerKeys;

  @override
  State<_SafetyNumbers> createState() => _SafetyNumbersState();
}

class _SafetyNumbersState extends State<_SafetyNumbers> {
  final Map<String, String> _numbers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    final crypto = di<CryptoManager>();
    for (final key in widget.peerKeys) {
      try {
        _numbers[key.id] = await crypto.safetyNumberFor(key);
      } catch (_) {
        // A key we cannot digest is shown without a number rather than failing
        // the whole screen.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_numbers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _numbers.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                entry.value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  letterSpacing: 1.2,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: entry.value));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Safety number copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.label,
    required this.detail,
    this.deviceLabel = '',
    this.isSelf = false,
  });

  final String label;
  final String detail;
  final String deviceLabel;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final timestamp = RatatoskTheme.of(context).timestamp;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isSelf ? Icons.phone_android : Icons.devices_other, color: timestamp),
      title: Row(
        children: [
          Flexible(child: Text(label.isEmpty ? 'Unknown device' : label)),
          if (deviceLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('· $deviceLabel', style: TextStyle(color: timestamp, fontSize: 12)),
            ),
        ],
      ),
      subtitle: Text(
        // The fingerprint in short form: enough to compare by eye against
        // another device's display, with the safety number for a real check.
        detail.length > 24 ? '${detail.substring(0, 24)}…' : detail,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// A compact lock badge for a conversation header.
///
/// It reports the truth rather than a reassurance: a conversation whose peer has
/// published no key cannot be encrypted to, and showing a padlock over it would
/// be the one kind of bug a user cannot detect.
class EncryptionBadge extends StatelessWidget {
  const EncryptionBadge({
    super.key,
    required this.verified,
    required this.canEncrypt,
    this.onTap,
  });

  /// Whether the user has confirmed the safety number for this conversation.
  final bool verified;

  /// Whether outgoing messages in this conversation can actually be sealed.
  final bool canEncrypt;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, tooltip) = switch ((canEncrypt, verified)) {
      (false, _) => (
          Icons.lock_open_outlined,
          scheme.error,
          'Not encrypted: this contact has no encryption keys yet — tap for details',
        ),
      (true, true) => (
          Icons.lock,
          scheme.primary,
          'Encrypted and verified — tap to review',
        ),
      (true, false) => (
          Icons.lock_outline,
          RatatoskTheme.of(context).timestamp,
          'Encrypted — tap to compare the safety number',
        ),
    };
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
    );
  }
}

/// A user avatar plus the safety-verification state, for the details page.
class SafetyNotice extends StatelessWidget {
  const SafetyNotice({super.key, required this.verified, required this.onVerify});

  final bool verified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: verified ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(verified ? Icons.verified_user : Icons.shield_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              verified
                  ? 'You verified this conversation.'
                  : 'Encrypted. Compare the safety number to be sure no one is in the middle.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(onPressed: onVerify, child: Text(verified ? 'Review' : 'Verify')),
        ],
      ),
    );
  }
}

/// Avatar plus name, drawn together in one row for the details page header.
class PersonHeader extends StatelessWidget {
  const PersonHeader({super.key, required this.name, required this.subtitle, this.avatar});

  final String name;
  final String subtitle;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        avatar ?? Avatar(name: name, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: TextStyle(color: RatatoskTheme.of(context).timestamp, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "I compared the numbers" — the one action that turns encryption into a
/// verified conversation. The verdict is stored locally, per conversation.
class _VerificationRow extends StatefulWidget {
  const _VerificationRow({required this.conversationId, required this.peerKeys});

  final String conversationId;
  final List<DeviceKey> peerKeys;

  @override
  State<_VerificationRow> createState() => _VerificationRowState();
}

class _VerificationRowState extends State<_VerificationRow> {
  @override
  Widget build(BuildContext context) {
    final state = di<AppState>();
    final verified = state.isVerified(widget.conversationId);
    final canVerify = widget.peerKeys.isNotEmpty && state.encryptionReady;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: !canVerify
            ? null
            : () {
                state.setVerified(widget.conversationId, !verified);
                setState(() {});
              },
        icon: Icon(verified ? Icons.verified_user : Icons.shield_outlined),
        label: Text(verified ? 'Mark as unverified' : 'The numbers match'),
      ),
    );
  }
}
