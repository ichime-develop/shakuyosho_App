import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import '../common/common_bottom_nav_bar.dart';

/// FR0100: ともだち一覧
/// - 友だちごとの貸借サマリを表示
/// - 詳細 / 借用書作成 / 取引追加 への導線を提供
/// - 下部は共通の `CommonBottomNavBar`
class Fr0100FriendsScreen extends ConsumerWidget {
  const Fr0100FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AppLog.i('open screen', ctx: context, data: {'screen': 'FR0100'});
    return Scaffold(
      appBar: AppBar(
        title: const Text('FR0100 ともだちリスト'),
        actions: [
          IconButton(
            onPressed: () => _Controller.onTapSearch(context),
            icon: const Icon(Icons.search),
            tooltip: 'けんさく',
          ),
          IconButton(
            onPressed: () => _Controller.onTapAddFriend(context),
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'ともだちをついか',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // サマリカード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _KpiTile(
                    label: 'ぜんいんすう',
                    value: '${_mockFriends.length}',
                    icon: Icons.group_outlined,
                  ),
                  _KpiTile(
                    label: 'かしているごうけい',
                    value: _fmtYen(_sumLend()),
                    icon: Icons.trending_up,
                  ),
                  _KpiTile(
                    label: 'かりているごうけい',
                    value: _fmtYen(_sumBorrow().abs()),
                    icon: Icons.trending_down,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 期限が近い（上位）
          if (_mockFriends.any((f) => f.dueAt != null)) ...[
            Text('きげんがちかい', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...(_mockFriends.where((f) => f.dueAt != null).toList()
                  ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!)))
                .take(3)
                .map(
                  (f) => _FriendRow(
                    data: f,
                    onOpenDetail: () =>
                        _Controller.onOpenFriendDetail(context, f.friendId),
                    onCreateLb: () =>
                        _Controller.onCreatePersonalLbFor(context, f.friendId),
                    onAddTx: () => _Controller.onAddPersonalTransactionFor(
                      context,
                      f.friendId,
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ],

          // 一覧
          Row(
            children: [
              Expanded(child: Text('ともだち', style: theme.textTheme.titleSmall)),
              TextButton(
                onPressed: () => _Controller.onTapSort(context),
                child: const Text('ならびかえ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._mockFriends.map(
            (f) => _FriendRow(
              data: f,
              onOpenDetail: () =>
                  _Controller.onOpenFriendDetail(context, f.friendId),
              onCreateLb: () =>
                  _Controller.onCreatePersonalLbFor(context, f.friendId),
              onAddTx: () =>
                  _Controller.onAddPersonalTransactionFor(context, f.friendId),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.data,
    required this.onOpenDetail,
    required this.onCreateLb,
    required this.onAddTx,
  });

  final FriendBalance data;
  final VoidCallback onOpenDetail;
  final VoidCallback onCreateLb;
  final VoidCallback onAddTx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlus = data.netAmount >= 0;
    final color = isPlus ? Colors.teal : Colors.deepOrange;

    Widget? dueBadge;
    if (data.dueAt != null) {
      final overdue = data.dueAt!.isBefore(DateTime.now());
      dueBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (overdue ? Colors.red : Colors.orange).withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          overdue ? 'きげんおくれ' : 'めやす ${_fmtDate(data.dueAt!)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: overdue ? Colors.red : Colors.orange,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(child: Text(data.displayName.characters.first)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.displayName, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      isPlus ? 'かしている' : 'かりている',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (dueBadge != null) ...[dueBadge, const SizedBox(width: 12)],
              Text(
                _fmtYen(data.netAmount.abs()) + (isPlus ? ' かし' : ' かり'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'lb') onCreateLb();
                  if (v == 'tx') onAddTx();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'lb', child: Text('しゃくようしょをつくる')),
                  PopupMenuItem(value: 'tx', child: Text('とりひきをついか')),
                ],
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------------------------
/// 最小 Controller（ハンドラ）
/// ---------------------------
class _Controller {
  static void onTapAddFriend(BuildContext context) {
    // TODO: 友だち追加導線（後日）
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ともだちついか: まだだよ')));
  }

  static void onTapSearch(BuildContext context) {
    // TODO: 検索導線（後日）
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('けんさく: まだだよ')));
  }

  static void onTapSort(BuildContext context) {
    // TODO: 並び替え（後日）
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ならびかえ: まだだよ')));
  }

  static void onOpenFriendDetail(BuildContext context, String friendId) {
    context.push('/fr0200?friendId=$friendId');
  }

  static void onCreatePersonalLbFor(BuildContext context, String friendId) {
    context.push('/lb0100?mode=create&friendId=$friendId');
  }

  static void onAddPersonalTransactionFor(
    BuildContext context,
    String friendId,
  ) {
    context.push('/tr0100?mode=personal&friendId=$friendId');
  }
}

/// ---------------------------
/// Mock データ（このファイル内に集約）
/// ---------------------------
class FriendBalance {
  final String friendId;
  final String displayName;
  final int netAmount; // 正=貸 / 負=借
  final DateTime? dueAt;
  const FriendBalance({
    required this.friendId,
    required this.displayName,
    required this.netAmount,
    this.dueAt,
  });
}

final List<FriendBalance> _mockFriends = [
  FriendBalance(
    friendId: 'u_ayaka',
    displayName: 'あやか',
    netAmount: -2000,
    dueAt: DateTime.now().add(const Duration(days: 1)),
  ),
  FriendBalance(
    friendId: 'u_sakaguchi',
    displayName: 'さかぐち',
    netAmount: 3500,
    dueAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  const FriendBalance(friendId: 'u_kenta', displayName: 'けんた', netAmount: 0),
  const FriendBalance(friendId: 'u_miki', displayName: 'みき', netAmount: 1800),
];

int _sumLend() => _mockFriends
    .where((f) => f.netAmount > 0)
    .fold(0, (p, e) => p + e.netAmount);
int _sumBorrow() => _mockFriends
    .where((f) => f.netAmount < 0)
    .fold(0, (p, e) => p + e.netAmount);

String _fmtYen(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final r = s.length - i;
    buf.write(s[i]);
    if (r > 1 && r % 3 == 1) buf.write(',');
  }
  return '¥${buf.toString()}';
}

String _fmtDate(DateTime d) {
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
