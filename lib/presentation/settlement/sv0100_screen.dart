import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

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

  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    eventId = q['eventId'] ?? 'ev_001';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventState = ref.watch(eventStateProvider);
    final ctx = _buildContextFromState(eventState, eventId);
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            _TransferList(transfers: transfers, contextData: ctx),
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

  void _goLb(_Transfer t) {
    // 個人借用書の作成パラメータで LB0100 へ（モック）
    final friendId = t.to; // 受け取り側が相手
    final eventTitle = _currentEventTitle();
    final uri = Uri(
      path: '/lb0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': friendId,
        'amount': t.amountYen.toString(),
        'memo': 'イベントのおかねまとめ($eventTitle)',
      },
    );
    context.push(uri.toString());
  }

  void _goTx(_Transfer t) {
    final eventTitle = _currentEventTitle();
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': t.to,
        'amount': t.amountYen.toString(),
        'memo': 'イベントのおかねまとめ($eventTitle)',
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

  String _currentEventTitle() {
    final state = ref.read(eventStateProvider);
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => state.events.first,
    );
    return event.title;
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
          child: Icon(
            Icons.handshake,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'けっか',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
          final from = contextData.members.firstWhere(
            (m) => m.userId == t.from,
          );
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
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.withOpacity(0.7),
                    ),
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

_EventSettleContext _buildContextFromState(EventState state, String eventId) {
  final event = state.events.firstWhere(
    (e) => e.id == eventId,
    orElse: () => state.events.first,
  );
  final txs = state.transactions
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList(growable: false);

  final memberIds = _resolveMemberIds(event, txs);
  final Map<String, int> paidMap = {for (final id in memberIds) id: 0};
  final Map<String, int> net = {for (final id in memberIds) id: 0};

  for (final tx in txs) {
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      final shares = tx.shares;
      if (paidBy == null || shares == null) continue;
      net.update(paidBy, (v) => v + tx.totalAmount,
          ifAbsent: () => tx.totalAmount);
      paidMap.update(paidBy, (v) => v + tx.totalAmount,
          ifAbsent: () => tx.totalAmount);
      shares.forEach((userId, amount) {
        net.update(userId, (v) => v - amount, ifAbsent: () => -amount);
      });
    } else {
      final fromUserId = tx.fromUserId;
      final toUserId = tx.toUserId;
      if (fromUserId == null || toUserId == null) continue;
      final amount = tx.repaymentAmount ?? tx.totalAmount;
      net.update(fromUserId, (v) => v + amount, ifAbsent: () => amount);
      net.update(toUserId, (v) => v - amount, ifAbsent: () => -amount);
    }
  }

  final members = memberIds
      .map(
        (id) => _Member(
          userId: id,
          displayName: displayNameOf(id),
          paidYen: paidMap[id] ?? 0,
        ),
      )
      .toList(growable: false);
  final total = paidMap.values.fold<int>(0, (p, e) => p + e);
  final eachShare = members.isEmpty ? 0 : (total / members.length).round();

  return _EventSettleContext(
    event: _EventLite(event.id, event.title),
    members: members,
    totalPaid: total,
    eachShare: eachShare,
    netBalances: net,
  );
}

List<String> _resolveMemberIds(EventSummary event, List<Transaction> txs) {
  final ids = <String>{...event.participantIds};
  for (final tx in txs) {
    if (tx.type == TxType.expense) {
      if (tx.paidBy != null) ids.add(tx.paidBy!);
      final shares = tx.shares;
      if (shares != null) ids.addAll(shares.keys);
    } else {
      if (tx.fromUserId != null) ids.add(tx.fromUserId!);
      if (tx.toUserId != null) ids.add(tx.toUserId!);
    }
  }
  return ids.toList(growable: false);
}

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
