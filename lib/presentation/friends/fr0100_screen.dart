import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/thread_providers.dart';
import 'package:shakuyousho_app/presentation/common/common_bottom_nav_bar.dart';

/// FR0100: スレッド一覧（個人/グループ）
class Fr0100ThreadListScreen extends ConsumerWidget {
  const Fr0100ThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalThreads = ref.watch(personalThreadsProvider);
    final groupThreads = ref.watch(groupThreadsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ともだち'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'こじん'),
              Tab(text: 'ぐるーぷ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PersonalThreadList(
              threads: personalThreads,
              onTap: (t) => _Controller.openThread(context, t.threadId),
            ),
            _GroupThreadList(
              threads: groupThreads,
              onTap: (t) => _Controller.openThread(context, t.threadId),
            ),
          ],
        ),
        bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
      ),
    );
  }
}

class _PersonalThreadList extends StatelessWidget {
  const _PersonalThreadList({required this.threads, required this.onTap});

  final List<PersonalThreadSummary> threads;
  final void Function(PersonalThreadSummary) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (threads.isEmpty) {
      return _EmptyState(
        message: '個人スレッドがまだありません。',
        theme: theme,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: threads.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: theme.dividerColor.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final thread = threads[index];
        final initial = thread.displayName.isEmpty
            ? '?'
            : thread.displayName.characters.first;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: CircleAvatar(child: Text(initial)),
          title: Text(thread.displayName),
          subtitle: Text('最終更新: ${thread.updatedAtLabel}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onTap(thread),
        );
      },
    );
  }
}

class _GroupThreadList extends StatelessWidget {
  const _GroupThreadList({required this.threads, required this.onTap});

  final List<GroupThreadSummary> threads;
  final void Function(GroupThreadSummary) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (threads.isEmpty) {
      return _EmptyState(
        message: 'グループスレッドがまだありません。',
        theme: theme,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: threads.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: theme.dividerColor.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final thread = threads[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(thread.groupName),
          subtitle: Text(
            '参加人数: ${thread.memberCount} ・ 最終更新: ${thread.updatedAtLabel}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onTap(thread),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.theme});

  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
    );
  }
}

class _Controller {
  static void openThread(BuildContext context, String threadId) {
    context.push('/fr0200/$threadId');
  }
}
