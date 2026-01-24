import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import '../common/common_bottom_nav_bar.dart';

/// FR0100: スレッド一覧（グループ）
/// - Thread 一覧を表示
/// - 下部は共通の `CommonBottomNavBar`
class Fr0100FriendsScreen extends ConsumerWidget {
  const Fr0100FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AppLog.i('open screen', ctx: context, data: {'screen': 'FR0100'});
    final threads = ref.watch(threadListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FR0100 スレッド一覧')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _KpiTile(
                    label: 'グループすう',
                    value: '${threads.length}',
                    icon: Icons.group_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (threads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'グループはまだありません。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            _ThreadList(threads: threads),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({required this.threads});

  final List<Thread> threads;

  @override
  Widget build(BuildContext context) {
    final sorted = [...threads]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Column(
      children: List.generate(sorted.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Divider(height: 1, color: Colors.grey.shade200);
        }
        final thread = sorted[index ~/ 2];
        return ListTile(
          leading: const Icon(Icons.group),
          title: Text(thread.title),
          subtitle: Text(
            'メンバー ${thread.participantIds.length}人 ・ ${_fmtDate(thread.updatedAt)}',
          ),
        );
      }),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _fmtDate(DateTime d) {
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
