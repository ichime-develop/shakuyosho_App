import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// SV0100: イベント精算画面
/// - メンバーの支払総額と負担割合からネット残高を算出
/// - "誰が誰へいくら払うか" の最小送金案（ヒューリスティック）を提示
/// - 各提案から「借用書発行(LB0100)」「取引へ(TR0100)」へ遷移（モック）
class Sv0100SettlementScreen extends ConsumerStatefulWidget {
  const Sv0100SettlementScreen({super.key});

  @override
  ConsumerState<Sv0100SettlementScreen> createState() =>
      _Sv0100SettlementScreenState();
}

class _Sv0100SettlementScreenState
    extends ConsumerState<Sv0100SettlementScreen> {
  late final String eventId;
  late _EventSettleContext ctx;

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    eventId = q['eventId'] ?? 'ev_001';
    // 本来は eventId からAPI/Repositoryで取得。今はモック。
    ctx = _buildContextFor(eventId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transfers = _minTransfers(ctx.netBalances);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('SV0100 精算：${ctx.event.title}'),
        actions: [
          IconButton(
            tooltip: '再計算',
            onPressed: () => setState(() {
              /* netBalances は不変。UIリビルドのみ */
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // 概要
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('イベント概要', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _kvRow('イベントID', ctx.event.eventId),
                  _kvRow(
                    '参加者',
                    ctx.members.map((m) => m.displayName).join(', '),
                  ),
                  _kvRow('支払合計', _fmtYen(ctx.totalPaid)),
                  _kvRow('1人あたり(均等)', _fmtYen(ctx.eachShare)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 支払内訳
          Text('支払内訳', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...ctx.members.map(
            (m) => ListTile(
              leading: CircleAvatar(child: Text(m.initial)),
              title: Text(m.displayName),
              subtitle: Text(
                '支払: ${_fmtYen(m.paidYen)} / 残高: ${_fmtYen(ctx.netBalances[m.userId] ?? 0)}',
              ),
              trailing: Text(
                (ctx.netBalances[m.userId] ?? 0) >= 0 ? '受取' : '支払',
                style: TextStyle(
                  color: (ctx.netBalances[m.userId] ?? 0) >= 0
                      ? Colors.teal
                      : Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 最小送金案
          Text('最小送金案（ヒューリスティック）', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (transfers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('清算は不要です。'),
              ),
            )
          else
            ...transfers.map(
              (t) => Card(
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text('${_nameOf(t.from)} → ${_nameOf(t.to)}'),
                  subtitle: Text(_fmtYen(t.amountYen)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'lb') _goLb(t);
                      if (v == 'tx') _goTx(t);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'lb', child: Text('借用書を発行(LB0100)')),
                      PopupMenuItem(value: 'tx', child: Text('取引に進む(TR0100)')),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
          // 一括ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: transfers.isEmpty
                      ? null
                      : () => _goCreateAllLb(transfers),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('全て借用書化(モック)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: transfers.isEmpty
                      ? null
                      : () => _goApplySettlement(transfers),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('精算を確定(モック)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nameOf(String userId) =>
      ctx.members.firstWhere((m) => m.userId == userId).displayName;

  void _goLb(_Transfer t) {
    // 個人借用書の作成パラメータで LB0100 へ（モック）
    final friendId = t.to; // 受け取り側が相手
    final uri = Uri(
      path: '/lb0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': friendId,
        'amount': t.amountYen.toString(),
        'memo': 'イベント精算(${ctx.event.title})',
      },
    );
    context.push(uri.toString());
  }

  void _goTx(_Transfer t) {
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': t.to,
        'amount': t.amountYen.toString(),
        'memo': 'イベント精算(${ctx.event.title})',
      },
    );
    context.push(uri.toString());
  }

  void _goCreateAllLb(List<_Transfer> list) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('借用書を ${list.length} 件作成（モック）')));
  }

  void _goApplySettlement(List<_Transfer> list) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('精算を確定しました（モック）')));
    context.go('/to0100/event');
  }
}

Widget _kvRow(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(k)),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// ---------------------------
/// Settlement ロジック（最小送金案の計算）
/// ---------------------------
class _Transfer {
  final String from; // 支払う人（負残高）
  final String to; // 受け取る人（正残高）
  final int amountYen;
  const _Transfer(this.from, this.to, this.amountYen);
}

/// 残高マップから最小送金案を作る（貪欲法）
List<_Transfer> _minTransfers(Map<String, int> net) {
  final debtors = <MapEntry<String, int>>[]; // 負
  final creditors = <MapEntry<String, int>>[]; // 正
  net.forEach((id, v) {
    if (v < 0) debtors.add(MapEntry(id, -v));
    if (v > 0) creditors.add(MapEntry(id, v));
  });
  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final res = <_Transfer>[];
  int i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final amt = d.value < c.value ? d.value : c.value;
    res.add(_Transfer(d.key, c.key, amt));
    final dLeft = d.value - amt;
    final cLeft = c.value - amt;
    if (dLeft == 0) {
      i++;
    } else {
      debtors[i] = MapEntry(d.key, dLeft);
    }
    if (cLeft == 0) {
      j++;
    } else {
      creditors[j] = MapEntry(c.key, cLeft);
    }
  }
  return res;
}

/// ---------------------------
/// モックデータと集計
/// ---------------------------
class _Member {
  final String userId;
  final String displayName;
  final int paidYen; // このイベントで立替た合計
  const _Member({
    required this.userId,
    required this.displayName,
    required this.paidYen,
  });
  String get initial => displayName.characters.first;
}

class _EventLite {
  final String eventId;
  final String title;
  const _EventLite(this.eventId, this.title);
}

class _EventSettleContext {
  final _EventLite event;
  final List<_Member> members;
  final int totalPaid;
  final int eachShare;
  final Map<String, int> netBalances; // +受取 / -支払
  _EventSettleContext({
    required this.event,
    required this.members,
    required this.totalPaid,
    required this.eachShare,
    required this.netBalances,
  });
}

_EventSettleContext _buildContextFor(String eventId) {
  // モック：イベントとメンバー
  final event = _mockEvents.firstWhere(
    (e) => e.eventId == eventId,
    orElse: () => const _EventLite('ev_001', '箱根旅行(2024/05)'),
  );
  final members = _mockMembers[event.eventId] ?? const <_Member>[];
  final total = members.fold<int>(0, (p, e) => p + e.paidYen);
  final each = members.isEmpty ? 0 : (total / members.length).round();
  final net = <String, int>{
    for (final m in members) m.userId: m.paidYen - each,
  };
  return _EventSettleContext(
    event: event,
    members: members,
    totalPaid: total,
    eachShare: each,
    netBalances: net,
  );
}

final _mockEvents = <_EventLite>[
  const _EventLite('ev_001', '箱根旅行(2024/05)'),
  const _EventLite('ev_002', '夏フェス(2024/08)'),
];

final Map<String, List<_Member>> _mockMembers = {
  'ev_001': const [
    _Member(userId: 'u_ayaka', displayName: 'あやか', paidYen: 12000),
    _Member(userId: 'u_sakaguchi', displayName: 'さかぐち', paidYen: 6000),
    _Member(userId: 'u_kenta', displayName: 'けんた', paidYen: 0),
  ],
  'ev_002': const [
    _Member(userId: 'u_ayaka', displayName: 'あやか', paidYen: 3000),
    _Member(userId: 'u_miki', displayName: 'みき', paidYen: 9000),
  ],
};

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
