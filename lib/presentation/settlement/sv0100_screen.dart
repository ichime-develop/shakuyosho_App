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
        title: Text('SV0100 おかねまとめ：${ctx.event.title}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        children: [
          const _HeroSection(),
          const SizedBox(height: 24),
          if (transfers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Text(
                'とくにやることはないよ。',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            )
          else
            _TransferList(
              transfers: transfers,
              contextData: ctx,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton.icon(
          onPressed: transfers.isEmpty
              ? null
              : () => _goApplySettlement(transfers),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const StadiumBorder(),
            elevation: 6,
          ),
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text(
            'せいさんかんりょう',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
        'memo': 'イベントのおかねまとめ(${ctx.event.title})',
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
        'memo': 'イベントのおかねまとめ(${ctx.event.title})',
      },
    );
    context.push(uri.toString());
  }

  void _goCreateAllLb(List<_Transfer> list) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('しゃくようしょを${list.length}けんつくったよ（モック）')),
    );
  }

  void _goApplySettlement(List<_Transfer> list) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('かくてい')));
    context.go('/to0100/event');
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.handshake, color: theme.colorScheme.primary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'けっか',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'だれがだれにいくらはらうか\nまとめておいたよ',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}

class _TransferList extends StatelessWidget {
  const _TransferList({required this.transfers, required this.contextData});
  final List<_Transfer> transfers;
  final _EventSettleContext contextData;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.08)),
          bottom: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
      ),
      child: Column(
        children: List.generate(transfers.length, (index) {
          final t = transfers[index];
          final from = contextData.members.firstWhere((m) => m.userId == t.from);
          final to = contextData.members.firstWhere((m) => m.userId == t.to);
          return Column(
            children: [
              _TransferRow(
                amount: t.amountYen,
                fromName: from.displayName,
                toName: to.displayName,
              ),
              if (index != transfers.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.6,
                  color: Colors.black.withOpacity(0.08),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.amount,
    required this.fromName,
    required this.toName,
  });

  final int amount;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _AvatarBadge(name: fromName, isReceiver: false),
          Expanded(
            child: Column(
              children: [
                Text(
                  _fmtYen(amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey.withOpacity(0.7)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'へ はらう',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          _AvatarBadge(name: toName, isReceiver: true),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name, required this.isReceiver});
  final String name;
  final bool isReceiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final baseColor = isReceiver
        ? theme.colorScheme.primary
        : Colors.deepOrangeAccent;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: baseColor,
                    fontSize: 20,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(
                    isReceiver ? Icons.add : Icons.remove,
                    size: 16,
                    color: isReceiver ? baseColor : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
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
