import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import '../common/common_bottom_nav_bar.dart';

/// FR0100: 友達一覧
/// - MockUser 一覧を表示
/// - 下部は共通の `CommonBottomNavBar`
class Fr0100FriendsScreen extends ConsumerWidget {
  const Fr0100FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AppLog.i('open screen', ctx: context, data: {'screen': 'FR0100'});
    final users = mockUsers.where((u) => u.userId != currentUserId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('FR0100 友達一覧')),
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
                    label: '友達の数',
                    value: '${users.length}',
                    icon: Icons.people_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '友達はまだいません。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            _UserList(users: users),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users});

  final List<MockUser> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(users.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Divider(height: 1, color: Colors.grey.shade200);
        }
        final user = users[index ~/ 2];
        return ListTile(
          leading: CircleAvatar(child: Text(user.displayName[0])),
          title: Text(user.displayName),
          subtitle: Text(user.userId),
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
