import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/presentation/common/common_bottom_nav_bar.dart';

/// FR0100: 友達一覧（坂口モデル準拠）
class Fr0100ThreadListScreen extends ConsumerStatefulWidget {
  const Fr0100ThreadListScreen({super.key});

  @override
  ConsumerState<Fr0100ThreadListScreen> createState() =>
      _Fr0100ThreadListScreenState();
}

class _Fr0100ThreadListScreenState
    extends ConsumerState<Fr0100ThreadListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summariesAsync = ref.watch(friendSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ともだち', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CupertinoSearchTextField(
              placeholder: 'けんさく',
              style: const TextStyle(),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
          // 友達一覧
          Expanded(
            child: summariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
              data: (summaries) {
                // 検索フィルタ
                final filtered = _searchQuery.isEmpty
                    ? summaries
                    : summaries
                          .where(
                            (s) => s.displayName.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'ともだち が いないよ',
                      style: TextStyle(fontSize: 16, color: theme.hintColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final summary = filtered[index];
                    return _FriendCard(
                      summary: summary,
                      onTap: () => _openFriendDetail(context, summary.friendId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 友達追加ボタン
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 220,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          onPressed: () => _showAddFriendDialog(context, ref),
          child: const Text(
            '＋ ともだち を ついか',
            style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }

  void _openFriendDetail(BuildContext context, String friendId) {
    context.push('/fr0200/$friendId');
  }

  Future<void> _showAddFriendDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('ともだち を ついか', style: TextStyle()),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: controller,
              placeholder: 'ユーザーID / なまえ',
              autofocus: true,
              style: const TextStyle(),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('やめる', style: TextStyle()),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final input = controller.text.trim();
                if (input.isEmpty) return;
                ref.read(friendActionsProvider.notifier).addFriend(input);
                Navigator.of(context).pop();
              },
              child: const Text('ついか', style: TextStyle()),
            ),
          ],
        );
      },
    );
  }
}

/// 友達カード（貸借サマリー表示）
class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.summary, required this.onTap});

  final FriendSummary summary;
  final VoidCallback onTap;

  String _fmtYen(int value) {
    final s = value.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名前
            Text(
              summary.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            // かした / かりた
            Row(
              children: [
                Text(
                  'かした：¥${_fmtYen(summary.lentTotal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'かりた：¥${_fmtYen(summary.borrowedTotal)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            // めやすのひ
            if (summary.nearestDueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'めやすのひ：${_fmtDate(summary.nearestDueDate!)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ],
        ),
      ),
    );
  }
}
