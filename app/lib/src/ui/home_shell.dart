import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../link_controller.dart';
import '../state/app_state.dart';
import 'chat_list_page.dart';
import 'chat_page.dart';
import 'join_screen.dart';

/// The signed-in shell.
///
/// One layout rule: wide screens show the list and the thread side by side (the
/// way Messenger's web and desktop apps do), narrow screens show one at a time.
/// The breakpoint is on width, not on the platform, so a resized desktop window
/// behaves like a phone.
class HomeShell extends WatchingWidget {
  const HomeShell({super.key});

  static const _sideBySideBreakpoint = 720.0;

  @override
  Widget build(BuildContext context) {
    // An invitation that arrived while signed in takes over the screen: it is
    // a deliberate user action, not something to do silently in the background.
    final links = watchIt<LinkController>();
    final pendingCode = links.pendingInviteCode;
    if (pendingCode != null) {
      return JoinScreen(code: pendingCode, onDone: links.clear);
    }
    return const _ShellBody();
  }
}

class _ShellBody extends StatefulWidget {
  const _ShellBody();

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sideBySide = width >= HomeShell._sideBySideBreakpoint;

    if (!sideBySide) {
      return const ChatListPage();
    }

    // On a wide screen the selection lives here rather than in a route, so the
    // list never disappears behind the thread.
    final selected = _selected;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 360,
            child: ChatListPage(
              selectedConversationId: selected,
              onSelect: (id) => setState(() => _selected = id),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected == null
                ? const _NoSelection()
                : ChatPaneHost(conversationId: selected),
          ),
        ],
      ),
    );
  }
}

/// Keeps the chat page alive for the length of a selection, so switching
/// conversations still calls `closeConversation` (which stops the typing
/// indicator and the read cursor).
class ChatPaneHost extends StatefulWidget {
  const ChatPaneHost({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatPaneHost> createState() => _ChatPaneHostState();
}

class _ChatPaneHostState extends State<ChatPaneHost> {
  @override
  void dispose() {
    di<AppState>().closeConversation(widget.conversationId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatPage(
      key: ValueKey(widget.conversationId),
      conversationId: widget.conversationId,
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('Pick a conversation', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
