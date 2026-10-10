import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../gen/ratatosk/v1/common.pb.dart';
import '../state/app_state.dart';
import 'chat_page.dart';
import 'invite_sheet.dart';
import 'theme.dart';
import 'widgets/avatar.dart';

/// Starts a conversation: find someone by name, add a contact, or create a
/// group. One sheet, three ways in, because they are the same intention.
Future<void> showNewChatSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const NewChatSheet(),
  );
}

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return DefaultTabController(
      length: 2,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Find people'),
                Tab(text: 'New group'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: const [
                  _FindPeopleTab(),
                  _NewGroupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search the server for accounts, add one as a contact, and open the chat.
class _FindPeopleTab extends StatefulWidget {
  const _FindPeopleTab();

  @override
  State<_FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends State<_FindPeopleTab> {
  final _query = TextEditingController();
  List<User> _results = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // An empty query lists recent accounts, so a small server has people to
    // find without typing anything.
    _search('');
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final users = await di<AppState>().searchUsers(query);
    if (!mounted) return;
    setState(() {
      _results = users;
      _loading = false;
    });
  }

  Future<void> _startChat(User user) async {
    final state = di<AppState>();
    final conversation = await state.startDirectChat(userId: user.id);
    if (!mounted || conversation == null) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatPage(conversationId: conversation.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _query,
            autofocus: true,
            onChanged: (value) => _search(value),
            decoration: const InputDecoration(
              hintText: 'Search by username or name',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 40, color: RatatoskTheme.of(context).timestamp),
                            const SizedBox(height: 12),
                            const Text('Nobody found'),
                            const SizedBox(height: 8),
                            // The two ways to reach someone who is not on this
                            // server yet.
                            FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                showInviteSheet(context);
                              },
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text('Invite them instead'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        return ListTile(
                          leading: Avatar.user(user, size: 44),
                          title: Text(user.displayName),
                          subtitle: Text('@${user.username}'),
                          trailing: const Icon(Icons.chat_bubble_outline),
                          onTap: () => _startChat(user),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

/// Build a group: a title and a set of members.
class _NewGroupTab extends StatefulWidget {
  const _NewGroupTab();

  @override
  State<_NewGroupTab> createState() => _NewGroupTabState();
}

class _NewGroupTabState extends State<_NewGroupTab> {
  final _title = TextEditingController();
  final _search = TextEditingController();
  final Set<String> _selected = {};
  List<User> _candidates = const [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _title.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() => _loading = true);
    final users = await di<AppState>().searchUsers(query);
    if (!mounted) return;
    setState(() {
      _candidates = users;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final state = di<AppState>();
    final title = _title.text.trim();
    if (title.isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);

    // The API takes handles; the sheet collects users, so translate here.
    final usernames = _candidates
        .where((user) => _selected.contains(user.id))
        .map((user) => user.username)
        .toList();
    final conversation = await state.startGroupChat(title, usernames);
    if (!mounted) return;
    setState(() => _creating = false);
    if (conversation == null) return;
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatPage(conversationId: conversation.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'Group name',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: _load,
            decoration: const InputDecoration(
              hintText: 'Add people',
              prefixIcon: Icon(Icons.person_add_alt),
            ),
          ),
        ),
        if (_selected.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _selected
                  .map((id) {
                    final user = _candidates.firstWhere((u) => u.id == id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        avatar: Avatar.user(user, size: 24),
                        label: Text(user.displayName),
                        onDeleted: () => setState(() => _selected.remove(id)),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _candidates.length,
                  itemBuilder: (context, index) {
                    final user = _candidates[index];
                    final checked = _selected.contains(user.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(user.id);
                        } else {
                          _selected.remove(user.id);
                        }
                      }),
                      secondary: Avatar.user(user, size: 40),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _creating || _title.text.trim().isEmpty || _selected.isEmpty ? null : _create,
              child: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Create group (${_selected.length})'),
            ),
          ),
        ),
      ],
    );
  }
}
