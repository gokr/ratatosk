import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:watch_it/watch_it.dart';

import '../gen/ratatosk/v1/social.pb.dart';
import '../link_controller.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'theme.dart';
import 'widgets/qr_code.dart';

/// Invitations: create a link, copy or share it, see what has been used, and
/// paste one that somebody sent you.
///
/// Everything lives in one sheet because the three actions belong to the same
/// intention ("get connected to someone who is not here yet").
Future<void> showInviteSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const InviteSheet(),
  );
}

class InviteSheet extends WatchingStatefulWidget {
  const InviteSheet({super.key});

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  final _codeField = TextEditingController();
  final _scrollController = ScrollController();
  Invite? _fresh;
  bool _creating = false;
  int _expiresInHours = 24 * 7;
  int _maxUses = 1;
  bool _showOptions = false;

  @override
  void dispose() {
    _codeField.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final invite = await di<AppState>().createInvite(
      expiresInHours: _expiresInHours,
      maxUses: _maxUses,
    );
    if (!mounted) return;
    setState(() {
      _fresh = invite;
      _creating = false;
      _showOptions = false;
    });
    // The QR is the reason this button was pressed; make sure it is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation link copied')),
    );
  }

  Future<void> _share(String url) async {
    // share_plus is present on every platform the app builds for; on desktop
    // it usually falls back to copying, which is still the right outcome.
    try {
      await SharePlus.instance.share(ShareParams(text: url, subject: 'Join me on Ratatosk'));
    } catch (_) {
      await _copy(url);
    }
  }

  void _pasteCode() {
    final code = _codeField.text.trim();
    if (code.isEmpty) return;
    di<LinkController>().submitCode(code);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = watchIt<AppState>();
    final invites = state.invites;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        // The sheet supplies the controller, which breaks animateTo(); use our
        // own so the QR can be scrolled to after it is created.
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Invite someone',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Show the QR, or send the link — either makes you contacts when they accept.',
            style: TextStyle(color: RatatoskTheme.of(context).timestamp),
          ),
          const SizedBox(height: 16),
          if (_fresh != null) ...[
            _InviteLinkCard(
              invite: _fresh!,
              onCopy: () => _copy(_fresh!.url),
              onShare: () => _share(_fresh!.url),
            ),
            const SizedBox(height: 16),
          ],
          if (_showOptions) ...[
            _OptionRow<int>(
              label: 'Expires',
              value: _expiresInHours,
              options: const {24: 'In a day', 24 * 7: 'In a week', 24 * 30: 'In a month', -1: 'Never'},
              onChanged: (value) => setState(() => _expiresInHours = value),
            ),
            _OptionRow<int>(
              label: 'Uses',
              value: _maxUses,
              options: const {1: 'Once', 5: 'Five times', -1: 'Unlimited'},
              onChanged: (value) => setState(() => _maxUses = value),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_link),
                  label: Text(_fresh == null ? 'Create a link' : 'Create another'),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showOptions = !_showOptions),
                tooltip: 'Options',
                icon: Icon(_showOptions ? Icons.tune : Icons.tune_outlined),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Have an invitation?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeField,
                  decoration: const InputDecoration(hintText: 'Paste a link or code'),
                  onSubmitted: (_) => _pasteCode(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: _pasteCode, child: const Text('Accept')),
            ],
          ),
          if (invites.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Your links', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...invites.map((invite) => _InviteRow(
                  invite: invite,
                  onCopy: () => _copy(invite.url),
                  onRevoke: () => state.revokeInvite(invite.code),
                )),
          ],
        ],
      ),
    );
  }
}

/// The freshly created link: a QR to hold up, and the link itself to send.
///
/// The QR is the point of the card — "show me your phone" is how people
/// actually exchange a contact these days — so it is shown first and large,
/// with the readable link and the buttons under it for every other case.
class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard({required this.invite, required this.onCopy, required this.onShare});

  final Invite invite;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // Big enough to scan from arm's length, but never taller than the sheet it
    // lives in on a phone.
    final qrSize = (size.shortestSide * 0.5).clamp(140.0, 240.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrCodeView(
                data: invite.url,
                size: qrSize,
                foreground: Colors.black,
                semanticLabel: 'Invitation QR code for ${invite.url}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Have them scan this',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.link, color: scheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  invite.url,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _describeUses(invite),
            style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.85), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy link'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _describeUses(Invite invite) {
    final uses = invite.maxUses <= 0 ? 'Unlimited uses' : '${invite.maxUses} use(s)';
    final expiry = invite.hasExpiresAt()
        ? 'expires ${ChatFormat.listTimestamp(invite.expiresAt.toDateTime(), use24Hour: di<AppState>().use24Hour)}'
        : 'never expires';
    return '$uses · $expiry';
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.onCopy, required this.onRevoke});

  final Invite invite;
  final VoidCallback onCopy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final timestamp = RatatoskTheme.of(context).timestamp;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        invite.valid ? Icons.link : Icons.link_off,
        color: invite.valid ? null : timestamp,
      ),
      title: Text(
        invite.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        invite.valid
            ? '${invite.uses} of ${invite.maxUses <= 0 ? '∞' : invite.maxUses} used'
            : 'No longer usable',
        style: TextStyle(color: timestamp, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Copy',
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 18),
          ),
          if (invite.valid)
            IconButton(
              tooltip: 'Revoke',
              onPressed: onRevoke,
              icon: const Icon(Icons.cancel_outlined, size: 18),
            ),
        ],
      ),
    );
  }
}

/// A labelled row of choices, used for expiry and use count.
class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: RatatoskTheme.of(context).timestamp)),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: options.entries
                  .map((entry) => ChoiceChip(
                        label: Text(entry.value),
                        selected: entry.key == value,
                        onSelected: (_) => onChanged(entry.key),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
