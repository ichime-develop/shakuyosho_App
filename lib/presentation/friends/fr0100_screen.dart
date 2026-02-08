import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/core/extensions/date_time_extension.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';
import 'package:shakuyousho_app/presentation/common/common_bottom_nav_bar.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';
import 'package:shakuyousho_app/presentation/friends/add_friend_sheet.dart';
import 'package:shakuyousho_app/presentation/common/app_loading_screen.dart';

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
  bool _didShowReadError = false;

  void _handleReadError(Object error, StackTrace stackTrace) {
    if (_didShowReadError) return;
    _didShowReadError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final err = toAppError(error, stackTrace);
      await showAppErrorDialog(context: context, error: err);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summariesAsync = ref.watch(friendSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ともだち',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: AppTextSizes.title,
            fontWeight: AppFontWeights.appBarTitle,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, size: 27),
            iconSize: 24,
            onPressed: () async {
              final result = await showAddFriendSheet(context);
              if (result == 'qr' && context.mounted) {
                context.push('/qr-scanner');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CupertinoSearchTextField(
              placeholder: 'けんさく',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.body,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
          ),
          // 友達一覧
          Expanded(
            child: summariesAsync.when(
              loading: () => const AppLoadingScreen(),
              error: (e, st) {
                _handleReadError(e, st);
                return Center(
                  child: Text(
                    AppMessages.dialog(AppMessageId.s004).message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      color: theme.hintColor,
                    ),
                  ),
                );
              },
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                        color: theme.hintColor,
                      ),
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
      // 友達追加は右上アイコンに統一
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }

  void _openFriendDetail(BuildContext context, String friendId) {
    context.push('/fr0200/$friendId');
  }
}

/// 友達カード（貸借サマリー表示）
class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.summary, required this.onTap});

  final FriendSummary summary;
  final VoidCallback onTap;

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.section,
                fontWeight: AppFontWeights.listTitle,
              ),
            ),
            const SizedBox(height: 6),
            // かした / かりた
            Row(
              children: [
                Text(
                  'かした：${summary.lentTotal.toYenSymbol()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    fontWeight: AppFontWeights.listSubtitle,
                    color: AppColors.lendAmount,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'かりた：${summary.borrowedTotal.toYenSymbol()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    fontWeight: AppFontWeights.listSubtitle,
                    color: AppColors.borrowAmount,
                  ),
                ),
              ],
            ),
            // めやすのひ
            if (summary.nearestDueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'きげん：${summary.nearestDueDate!.toYmdSlash()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: AppTextSizes.small,
                  fontWeight: AppFontWeights.listSubtitle,
                  color: AppColors.iconDefault,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.listBorder),
          ],
        ),
      ),
    );
  }
}
