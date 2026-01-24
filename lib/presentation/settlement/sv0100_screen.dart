import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

/// SV0100: イベント精算画面
/// - メンバーの支払総額と負担割合からネット残高を算出
/// - "誰が誰へいくら払うか" の最小送金案（ヒューリスティック）を提示
/// - 各提案から「借用書発行(LB0100)」「取引へ(TR0100)」へ遷移（モック）
class Sv0100SettlementScreen extends ConsumerStatefulWidget {
  const Sv0100SettlementScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<Sv0100SettlementScreen> createState() =>
      _Sv0100SettlementScreenState();
}

class _Sv0100SettlementScreenState
    extends ConsumerState<Sv0100SettlementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventId = widget.eventId;
    if (eventId.isEmpty) {
      return _EventErrorView(
        title: 'SV0100 おかねまとめ',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final eventMeta = ref.watch(eventMetaProvider(eventId));
    if (eventMeta == null) {
      return _EventErrorView(
        title: 'SV0100 おかねまとめ',
        message: 'イベントが見つかりません。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final settlement = ref.watch(settlementProvider(eventId));
    final transfers =
        settlement?.instructions ?? const <SettlementInstruction>[];
    final eventTitle = eventMeta.title;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('SV0100 おかねまとめ：$eventTitle'),
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
            _TransferList(transfers: transfers),
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

  void _goLb(SettlementInstruction t) {
    // 個人借用書の作成パラメータで LB0100 へ（モック）
    final friendId = t.toUserId; // 受け取り側が相手
    final eventTitle = _currentEventTitle();
    final uri = Uri(
      path: '/lb0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': friendId,
        'amount': t.amount.toString(),
        'memo': 'イベントのおかねまとめ($eventTitle)',
      },
    );
    context.push(uri.toString());
  }

  void _goTx(SettlementInstruction t) {
    final eventTitle = _currentEventTitle();
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {
        'mode': 'personal',
        'friendId': t.toUserId,
        'amount': t.amount.toString(),
        'memo': 'イベントのおかねまとめ($eventTitle)',
      },
    );
    context.push(uri.toString());
  }

  void _goCreateAllLb(List<SettlementInstruction> list) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('しゃくようしょを${list.length}けんつくったよ（モック）')),
    );
  }

  void _goApplySettlement(List<SettlementInstruction> list) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('かくてい')));
    context.go('/to0100/event');
  }

  String _currentEventTitle() {
    final activeEventId = widget.eventId;
    if (activeEventId.isEmpty) {
      return 'イベント';
    }
    final meta = ref.read(eventMetaProvider(activeEventId));
    return meta?.title ?? 'イベント';
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
  const _TransferList({required this.transfers});
  final List<SettlementInstruction> transfers;

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
          final fromName = displayNameOf(t.fromUserId);
          final toName = displayNameOf(t.toUserId);
          return Column(
            children: [
              _TransferRow(
                amount: t.amount,
                fromName: fromName,
                toName: toName,
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

class _EventErrorView extends StatelessWidget {
  const _EventErrorView({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                child: const Text('EV0100にもどる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
