import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../common/common_bottom_nav_bar.dart';

/// TO0100: ホーム（個人 / イベント タブ）
/// - ヘッダー: タイトル + 通知
/// - タブ: 個人 / イベント
/// - フッター: ホーム / ともだち / じぶん
class To0100Screen extends ConsumerStatefulWidget {
  const To0100Screen({super.key, this.initialTab = 0});

  /// 0: 個人, 1: イベント — ルート（/to0100/personal|event）と同期
  final int initialTab;

  @override
  ConsumerState<To0100Screen> createState() => _To0100ScreenState();
}

class _To0100ScreenState extends ConsumerState<To0100Screen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    // タブ変更時にURLと同期（/to0100/personal or /to0100/event）
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // アニメ中の重複発火を回避
      final path = _tabController.index == 0
          ? '/to0100/personal'
          : '/to0100/event';
      final current = _currentLocation;
      if (current != path) context.go(path);
    });
  }

  @override
  void didUpdateWidget(covariant To0100Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != _tabController.index &&
        widget.initialTab >= 0 &&
        widget.initialTab < _tabController.length) {
      _tabController.animateTo(widget.initialTab);
    }
  }

  String get _currentLocation {
    final info = GoRouter.of(context).routeInformationProvider.value;
    return info.uri.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 個人 / イベントのFABを出し分け
  Widget _buildFab(BuildContext context) {
    if (_tabController.index == 0) {
      return _PersonalFab(
        onAddTransaction: () => _Controller.onAddPersonalTransaction(context),
        onCreateLb: () => _Controller.onCreatePersonalLb(context),
      );
    } else {
      return _EventFab(
        onCreateEvent: () => _Controller.onCreateEvent(context),
        onComputeSettlement: () => _Controller.onComputeSettlement(context),
      );
    }
  }

  // フッターの選択値は CommonBottomNavBar に移譲

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('しゃくよーしょ'),
        actions: [
          IconButton(
            onPressed: () => _Controller.onOpenNotifications(context),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '個人', icon: Icon(Icons.person_outline)),
            Tab(text: 'イベント', icon: Icon(Icons.event_note)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PersonalTabView(), _EventTabView()],
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 1),
    );
  }
}

/// ---------------------------
/// 個人タブ
/// ---------------------------
class _PersonalTabView extends StatelessWidget {
  const _PersonalTabView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = _mockPersonalSummary.lendTotal;
    final neg = _mockPersonalSummary.borrowTotal;

    return ListView(
      key: const PageStorageKey('to0100_personal'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // あなたの残高カード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('あなたの残高', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          label: '貸している',
                          value: _fmtYen(pos),
                          valueColor: Colors.teal,
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiTile(
                          label: '借りている',
                          value: _fmtYen(neg),
                          valueColor: Colors.deepOrange,
                          icon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 期限切迫（上位3）
        if (_mockUrgentDueFriends.isNotEmpty) ...[
          Text('期限が近い（上位）', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._mockUrgentDueFriends
              .take(3)
              .map(
                (f) => _FriendRow(
                  data: f,
                  onTap: () =>
                      _Controller.onOpenFriendDetail(context, f.friendId),
                  onQuickLb: () =>
                      _Controller.onCreatePersonalLbFor(context, f.friendId),
                  onQuickTx: () => _Controller.onAddPersonalTransactionFor(
                    context,
                    f.friendId,
                  ),
                ),
              ),
          const SizedBox(height: 12),
        ],

        // 友だち一覧（残高）
        Row(
          children: [
            Expanded(child: Text('友だち一覧', style: theme.textTheme.titleSmall)),
            TextButton(
              onPressed: () => _Controller.onOpenFriends(context),
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._mockFriends.map(
          (f) => _FriendRow(
            data: f,
            onTap: () => _Controller.onOpenFriendDetail(context, f.friendId),
            onQuickLb: () =>
                _Controller.onCreatePersonalLbFor(context, f.friendId),
            onQuickTx: () =>
                _Controller.onAddPersonalTransactionFor(context, f.friendId),
          ),
        ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.data,
    required this.onTap,
    required this.onQuickLb,
    required this.onQuickTx,
  });

  final FriendBalance data;
  final VoidCallback onTap;
  final VoidCallback onQuickLb;
  final VoidCallback onQuickTx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlus = data.netAmount >= 0;
    final color = isPlus ? Colors.teal : Colors.deepOrange;
    final dueBadge = data.dueAt == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (data.isOverdue ? Colors.red : Colors.orange).withOpacity(
                0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.isOverdue ? '期限超過' : '期限 ${_fmtDate(data.dueAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: data.isOverdue ? Colors.red : Colors.orange,
              ),
            ),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      isPlus ? 'あなたが貸している' : 'あなたが借りている',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (dueBadge != null) ...[dueBadge, const SizedBox(width: 12)],
              Text(
                _fmtYen(data.netAmount.abs()) + (isPlus ? ' 貸' : ' 借'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'lb') onQuickLb();
                  if (v == 'tx') onQuickTx();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'lb', child: Text('借用書を作成')),
                  PopupMenuItem(value: 'tx', child: Text('取引を追加')),
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

/// ---------------------------
/// イベントタブ
/// ---------------------------
class _EventTabView extends StatelessWidget {
  const _EventTabView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final inProgress = _mockEvents.where((e) => e.inProgress).toList();
    final finished = _mockEvents.where((e) => !e.inProgress).toList();

    return ListView(
      key: const PageStorageKey('to0100_event'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // サマリ
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _KpiTile(
                  label: '進行中イベント',
                  value: '${inProgress.length}',
                  icon: Icons.play_circle_outline,
                ),
                _KpiTile(
                  label: '未清算合計',
                  value: _fmtYen(
                    inProgress.fold<int>(0, (p, e) => p + e.unsettledAmount),
                  ),
                  icon: Icons.payments_outlined,
                ),
                _KpiTile(
                  label: '未承認の記録',
                  value:
                      '${inProgress.fold<int>(0, (p, e) => p + e.pendingCount)}',
                  icon: Icons.pending_actions_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 進行中イベント
        Row(
          children: [
            Expanded(
              child: Text('進行中のイベント', style: theme.textTheme.titleSmall),
            ),
            TextButton(
              onPressed: () => _Controller.onOpenEventList(context),
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...inProgress.map(
          (e) => _EventCard(
            data: e,
            onTap: () => _Controller.onOpenEventDetail(context, e.eventId),
            onAddTx: () =>
                _Controller.onAddEventTransaction(context, e.eventId),
            onSettle: () =>
                _Controller.onComputeSettlementFor(context, e.eventId),
          ),
        ),

        // 過去イベント（抜粋）
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('最近のイベント（完了）', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...finished
              .take(3)
              .map(
                (e) => _EventCard(
                  data: e,
                  onTap: () =>
                      _Controller.onOpenEventDetail(context, e.eventId),
                  onAddTx: () =>
                      _Controller.onAddEventTransaction(context, e.eventId),
                  onSettle: () =>
                      _Controller.onComputeSettlementFor(context, e.eventId),
                ),
              ),
        ],
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.data,
    required this.onTap,
    required this.onAddTx,
    required this.onSettle,
  });

  final EventSummary data;
  final VoidCallback onTap;
  final VoidCallback onAddTx;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = data.inProgress ? Colors.blue : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.event, color: badgeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtDate(data.start)}〜${_fmtDate(data.end)}｜参加${data.memberCount}人',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '未清算 ${_fmtYen(data.unsettledAmount)} / 未承認 ${data.pendingCount}件',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _SmallBtn(text: '取引', icon: Icons.add, onPressed: onAddTx),
                  const SizedBox(height: 6),
                  _SmallBtn(
                    text: '清算',
                    icon: Icons.calculate_outlined,
                    onPressed: onSettle,
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// 下部：共通パーツ
/// ---------------------------
class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Row(
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
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  const _SmallBtn({
    required this.text,
    required this.icon,
    required this.onPressed,
  });
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 36),
      ),
    );
  }
}

/// ---------------------------
/// 最小Controller（ハンドラ集約）
/// 実際の実装では UseCase/Provider に接続してください
/// ---------------------------
class _Controller {
  // ルーティング系
  static void onOpenNotifications(BuildContext context) {
    // TODO: 通知一覧へ（未実装）
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('通知：未実装')));
  }

  static void onOpenFriends(BuildContext context) => context.go('/fr0100');
  static void onOpenFriendDetail(BuildContext context, String friendId) =>
      context.go('/fr0200?friendId=$friendId');

  static void onOpenMy(BuildContext context) => context.go('/my0100');

  static void onOpenEventList(BuildContext context) => context.go('/ev0100');
  static void onOpenEventDetail(BuildContext context, String eventId) =>
      context.go('/ev0200?eventId=$eventId');

  // 個人タブアクション
  static void onAddPersonalTransaction(BuildContext context) {
    // 相手選択モーダル→ TR0100 へ、ここはダミー
    context.go('/tr0100?mode=personal');
  }

  static void onCreatePersonalLb(BuildContext context) {
    context.go('/lb0100?mode=create');
  }

  static void onCreatePersonalLbFor(BuildContext context, String friendId) {
    context.go('/lb0100?mode=create&friendId=$friendId');
  }

  static void onAddPersonalTransactionFor(
    BuildContext context,
    String friendId,
  ) {
    context.go('/tr0100?mode=personal&friendId=$friendId');
  }

  // イベントタブアクション
  static void onCreateEvent(BuildContext context) {
    context.go('/gr0100'); // 新規イベント/グループ作成
  }

  static void onComputeSettlement(BuildContext context) {
    context.go('/sv0100'); // 直近イベントを仮定（実装時は選択）
  }

  static void onAddEventTransaction(BuildContext context, String eventId) {
    context.go('/tr0100?mode=event&eventId=$eventId');
  }

  static void onComputeSettlementFor(BuildContext context, String eventId) {
    context.go('/sv0100?eventId=$eventId');
  }
}

/// ---------------------------
/// FAB（個人）
/// ---------------------------
class _PersonalFab extends StatelessWidget {
  const _PersonalFab({
    required this.onAddTransaction,
    required this.onCreateLb,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onCreateLb;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab_lb',
          onPressed: onCreateLb,
          label: const Text('借用書を発行'),
          icon: const Icon(Icons.description_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fab_tx',
          onPressed: onAddTransaction,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// ---------------------------
/// FAB（イベント）
/// ---------------------------
class _EventFab extends StatelessWidget {
  const _EventFab({
    required this.onCreateEvent,
    required this.onComputeSettlement,
  });

  final VoidCallback onCreateEvent;
  final VoidCallback onComputeSettlement;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab_settle',
          onPressed: onComputeSettlement,
          label: const Text('清算を計算'),
          icon: const Icon(Icons.calculate_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fab_event',
          onPressed: onCreateEvent,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// =============================================================
/// 以降、画面内で使用する Mock データ定義（1か所集約）
/// 実装時は Repository/Provider で差し替え
/// =============================================================

class PersonalSummary {
  final int lendTotal; // ＋（貸）
  final int borrowTotal; // −（借）
  const PersonalSummary({required this.lendTotal, required this.borrowTotal});
}

class FriendBalance {
  final String friendId;
  final String displayName;
  final int netAmount; // 正=相手に貸してる / 負=自分が借りてる（円）
  final DateTime? dueAt; // 期限
  const FriendBalance({
    required this.friendId,
    required this.displayName,
    required this.netAmount,
    this.dueAt,
  });

  bool get isOverdue => dueAt != null && dueAt!.isBefore(DateTime.now());
}

class EventSummary {
  final String eventId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool inProgress;
  final int unsettledAmount; // 未清算合計
  final int pendingCount; // 未承認件数
  final int memberCount;

  const EventSummary({
    required this.eventId,
    required this.title,
    required this.start,
    required this.end,
    required this.inProgress,
    required this.unsettledAmount,
    required this.pendingCount,
    required this.memberCount,
  });
}

// ---- Mock 実データ ----
const _mockPersonalSummary = PersonalSummary(
  lendTotal: 12000,
  borrowTotal: 8000,
);

final List<FriendBalance> _mockUrgentDueFriends = [
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
    dueAt: DateTime.now().subtract(const Duration(days: 1)), // overdue
  ),
];

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

final List<EventSummary> _mockEvents = [
  EventSummary(
    eventId: 'e_trip2025',
    title: '旅行 2025 春',
    start: DateTime(2025, 4, 28),
    end: DateTime(2025, 5, 2),
    inProgress: true,
    unsettledAmount: 3500,
    pendingCount: 2,
    memberCount: 4,
  ),
  EventSummary(
    eventId: 'e_dinner_team',
    title: '飲み会チーム',
    start: DateTime(2025, 10, 1),
    end: DateTime(2025, 10, 1),
    inProgress: true,
    unsettledAmount: 0,
    pendingCount: 1,
    memberCount: 5,
  ),
  EventSummary(
    eventId: 'e_hokkaido',
    title: '北海道合宿',
    start: DateTime(2024, 9, 1),
    end: DateTime(2024, 9, 3),
    inProgress: false,
    unsettledAmount: 0,
    pendingCount: 0,
    memberCount: 6,
  ),
];

// ---- 表示用ユーティリティ ----
String _fmtYen(int n) {
  // シンプルな千区切り（Intl 未使用）
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
