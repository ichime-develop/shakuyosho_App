import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import '../common/common_bottom_nav_bar.dart';

/// TO0100: ホーム（こじん / いべんと タブ）
/// - タブ: こじん / いべんと
/// - フッター: ほーむ / ともだち / いべんと / じぶん
class To0100Screen extends ConsumerStatefulWidget {
  const To0100Screen({super.key, this.initialTab = 0});

  /// 0: こじん, 1: いべんと — ルート（/to0100/personal|event）と同期
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
        title: const Text('しゃくよーしょ'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            final path = index == 0 ? '/to0100/personal' : '/to0100/event';
            context.replace(path);
            _tabController.index = index;
          },
          tabs: const [
            Tab(text: 'こじん', icon: Icon(Icons.person_outline)),
            Tab(text: 'いべんと', icon: Icon(Icons.event_note)),
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
class _PersonalTabView extends ConsumerWidget {
  const _PersonalTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalsAsync = ref.watch(loanTotalsProvider);
    final summariesAsync = ref.watch(friendSummariesProvider);

    return totalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('えらー: $e')),
      data: (totals) => summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('えらー: $e')),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('あなたのざんだか', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _KpiTile(
                              label: 'かしている',
                              value: _fmtYen(totals.lentTotal),
                              valueColor: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiTile(
                              label: 'かりている',
                              value: _fmtYen(totals.borrowedTotal),
                              valueColor: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ともだちリスト
              Row(
                children: [
                  Expanded(
                    child: Text('ともだち', style: theme.textTheme.titleSmall),
                  ),
                  TextButton(
                    onPressed: () => context.go('/fr0100'),
                    child: const Text('ぜんぶみる'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (summaries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('かしかりしているともだちはいないよ')),
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
    final color = isPlus ? Colors.teal : Colors.deepOrange;

    return ListTile(
      title: Text(summary.displayName),
      subtitle: Row(
        children: [
          if (summary.lentTotal > 0)
            Text(
              'かし ${_fmtYen(summary.lentTotal)}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal),
            ),
          if (summary.lentTotal > 0 && summary.borrowedTotal > 0)
            const SizedBox(width: 8),
          if (summary.borrowedTotal > 0)
            Text(
              'かり ${_fmtYen(summary.borrowedTotal)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.deepOrange,
              ),
            ),
        ],
      ),
      trailing: Text(
        '${isPlus ? '+' : ''}${_fmtYen(balance)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// いべんとタブ
// ─────────────────────────────────────────────────────────────────
class _EventTabView extends ConsumerWidget {
  const _EventTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metas = ref.watch(eventMetaListProvider);

    // 進行中（status == inProgress）のイベントのみ、最近順で上位5件
    final inProgress =
        metas
            .where(
              (e) => e.deletedAt == null && e.status == EventStatus.inProgress,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final top5 = inProgress.take(5).toList();

    return ListView(
      key: const PageStorageKey('to0100_event'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ヘッダー
        Row(
          children: [
            Expanded(
              child: Text('しんこうちゅうのいべんと', style: theme.textTheme.titleSmall),
            ),
            TextButton(
              onPressed: () => context.push('/ev0100'),
              child: const Text('ぜんぶみる'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (top5.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('しんこうちゅうのいべんとはないよ')),
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
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
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
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 表示用ユーティリティ
// ─────────────────────────────────────────────────────────────────
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
