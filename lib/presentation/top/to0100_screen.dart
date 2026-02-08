import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/app_loading_screen.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';
import '../common/common_bottom_nav_bar.dart';

/// TO0100: ホーム（こじん / イベント タブ）
/// - タブ: こじん / イベント
/// - フッター: ほーむ / ともだち / イベント / じぶん
class To0100Screen extends ConsumerStatefulWidget {
  const To0100Screen({super.key, this.initialTab = 0});

  /// 0: こじん, 1: イベント — ルート（/to0100/personal|event）と同期
  final int initialTab;

  @override
  ConsumerState<To0100Screen> createState() => _To0100ScreenState();
}

class _To0100ScreenState extends ConsumerState<To0100Screen>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        ScreenLogMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    logInit('TO0100');
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void didUpdateWidget(covariant To0100Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != _tabController.index &&
        widget.initialTab >= 0 &&
        widget.initialTab < _tabController.length) {
      _tabController.index = widget.initialTab;
    }
  }

  @override
  void dispose() {
    logDispose('TO0100');
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    logBuild(context, 'TO0100');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'しゃくよーしょ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppTextSizes.title,
            fontWeight: AppFontWeights.appBarTitle,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.iconDefault,
          onTap: (index) {
            final path = index == 0 ? '/to0100/personal' : '/to0100/event';
            context.replace(path);
            _tabController.index = index;
          },
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.label,
          ),
          unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(
                fontSize: AppTextSizes.body,
                fontWeight: AppFontWeights.listSubtitle,
              ),
          tabs: const [
            Tab(text: 'こじん', icon: Icon(Icons.person_outline)),
            Tab(text: 'イベント', icon: Icon(Icons.event_note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PersonalTabView(), _EventTabView()],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// こじんタブ
// ─────────────────────────────────────────────────────────────────
class _PersonalTabView extends ConsumerStatefulWidget {
  const _PersonalTabView();

  @override
  ConsumerState<_PersonalTabView> createState() => _PersonalTabViewState();
}

class _PersonalTabViewState extends ConsumerState<_PersonalTabView> {
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
    final totalsAsync = ref.watch(loanTotalsProvider);
    final summariesAsync = ref.watch(friendSummariesProvider);

    return totalsAsync.when(
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
      data: (totals) => summariesAsync.when(
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
        data: (allSummaries) {
          // 未完済Loanがある友だちのみ
          final summaries = allSummaries
              .where((s) => s.hasOutstanding)
              .take(5)
              .toList();

          return ListView(
            key: const PageStorageKey('to0100_personal'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // サマリカード
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.summaryCardBackground,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: AppShadows.subtle,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'あなたのざんだか',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: AppTextSizes.section,
                        fontWeight: AppFontWeights.sectionTitle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: 'かしている',
                            value: totals.lentTotal.toYenSymbol(),
                            valueColor: AppColors.lendAmount,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiTile(
                            label: 'かりている',
                            value: totals.borrowedTotal.toYenSymbol(),
                            valueColor: AppColors.borrowAmount,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ともだちリスト
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ともだち',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: AppTextSizes.section,
                        fontWeight: AppFontWeights.sectionTitle,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/fr0100'),
                    child: Text(
                      'ぜんぶみる',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                        fontWeight: AppFontWeights.listSubtitle,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (summaries.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'かしかりしているともだちはいないよ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                )
              else
                ...summaries.map(
                  (s) => _FriendRow(
                    summary: s,
                    onTap: () => context.push('/fr0200/${s.friendId}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.summary, required this.onTap});

  final FriendSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = summary.balance;
    final isPlus = balance >= 0;
    final color = isPlus ? AppColors.lendAmount : AppColors.borrowAmount;

    return ListTile(
      title: Text(
        summary.displayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: AppTextSizes.section,
          fontWeight: AppFontWeights.listTitle,
        ),
      ),
      subtitle: Row(
        children: [
          if (summary.lentTotal > 0)
            Text(
              'かし ${summary.lentTotal.toYenSymbol()}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: AppTextSizes.small,
                fontWeight: AppFontWeights.listSubtitle,
                color: AppColors.lendAmount,
              ),
            ),
          if (summary.lentTotal > 0 && summary.borrowedTotal > 0)
            const SizedBox(width: 8),
          if (summary.borrowedTotal > 0)
            Text(
              'かり ${summary.borrowedTotal.toYenSymbol()}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: AppTextSizes.small,
                fontWeight: AppFontWeights.listSubtitle,
                color: AppColors.borrowAmount,
              ),
            ),
        ],
      ),
      trailing: Text(
        '${isPlus ? '+' : ''}${balance.toYenSymbol()}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontSize: AppTextSizes.section,
          fontWeight: AppFontWeights.listTitle,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// イベントタブ
// ─────────────────────────────────────────────────────────────────
class _EventTabView extends ConsumerStatefulWidget {
  const _EventTabView();

  @override
  ConsumerState<_EventTabView> createState() => _EventTabViewState();
}

class _EventTabViewState extends ConsumerState<_EventTabView> {
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
    // 進行中（status == inProgress）のイベントのみ、
    // 「取引があった順（最近順）」で上位5件
    List<EventMeta> top5;
    try {
      top5 = ref
          .watch(inProgressEventMetasByRecentTxProvider)
          .take(5)
          .toList();
    } catch (e, st) {
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
    }

    return ListView(
      key: const PageStorageKey('to0100_event'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ヘッダー
        Row(
          children: [
            Expanded(
              child: Text(
                'しんこうちゅうのイベント',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: AppTextSizes.section,
                  fontWeight: AppFontWeights.sectionTitle,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/ev0100'),
              child: Text(
                'ぜんぶみる',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.listSubtitle,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (top5.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'しんこうちゅうのイベントはないよ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  color: theme.hintColor,
                ),
              ),
            ),
          )
        else
          ...top5.map(
            (e) => _EventRow(
              title: e.title,
              onTap: () => context.push('/ev0200/${e.id}'),
            ),
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: AppTextSizes.section,
          fontWeight: AppFontWeights.listTitle,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconDefault),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 共通パーツ
// ─────────────────────────────────────────────────────────────────
class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: AppTextSizes.small,
            fontWeight: AppFontWeights.label,
            color: AppColors.iconDefault,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontSize: AppTextSizes.section,
            fontWeight: AppFontWeights.listTitle,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 表示用ユーティリティ
// ─────────────────────────────────────────────────────────────────
