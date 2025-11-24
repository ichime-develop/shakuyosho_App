import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// EV0200: イベント詳細（支払い一覧）
///
/// レイアウト仕様:
/// 1. AppBar: 画面ID + イベント名のみ表示
/// 2. ボディ: 支払いイベント単位のカード一覧
///    - イベント名
///    - 記載した日付
///    - 金額
///    - 誰が支払ったか
///    カードタップで TR0100 に遷移（編集）
/// 3. 下部ボタン:
///    - 「追加」: TR0100 へ遷移（新規）
///    - 「清算」: SV0100 へ遷移
/// ※ この画面から借用書(LB0100)には遷移しない
class Ev0200EventDetailScreen extends ConsumerWidget {
  const Ev0200EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qp = Uri.base.queryParameters;
    final eventId = qp['eventId'] ?? 'ev_001';

    final event = _mockEvents.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => _mockEvents.first,
    );

    // 本来は eventId に紐づく支払い一覧を Provider から取得する想定
    final payments = _mockPayments
        .where((p) => p.eventId == event.eventId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)); // 新しい順

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('EV0200 ${event.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'イベントを削除',
            onPressed: () => _Controller.confirmAndDeleteEvent(
              context: context,
              eventId: event.eventId,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: payments.isEmpty
                ? Center(
                    child: Text(
                      'このイベントの支払いはまだ登録されていません。\n「追加」ボタンから支払いを登録できます。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () => _Controller.goEditEventTransaction(
                            context: context,
                            eventId: event.eventId,
                            payment: p,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 左側: タイトル + サブ情報
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '記載日: ${_fmtDateTime(p.recordedAt)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: theme.hintColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '支払った人: ${p.payerName}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 右側: 金額 + 削除ボタン
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _fmtYen(p.amount),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: '支払いを削除',
                                      onPressed: () => _onDeletePayment(context, p.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 下部の操作ボタン
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _Controller.goAddEventTransaction(
                      context: context,
                      eventId: event.eventId,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('追加'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _Controller.goSettlement(
                      context: context,
                      eventId: event.eventId,
                    ),
                    child: const Text('清算'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeletePayment(BuildContext context, String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('支払いを削除'),
        content: const Text(
          'この支払いを削除しますか？\n'
          '元に戻すことはできません。（モック段階の文言）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Mock deletion
    _mockPayments.removeWhere((p) => p.id == paymentId);

    // Rebuild UI (force refresh)
    (context as Element).markNeedsBuild();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('支払いを削除しました（モック）')),
    );
  }
}

class _Controller {
  /// 清算ボタン → SV0100
  static void goSettlement({
    required BuildContext context,
    required String eventId,
  }) {
    final uri = Uri(
      path: '/sv0100',
      queryParameters: {
        'eventId': eventId,
      },
    );
    context.push(uri.toString());
  }

  /// 追加ボタン → TR0100（新規）
  static void goAddEventTransaction({
    required BuildContext context,
    required String eventId,
  }) {
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {
        'eventId': eventId,
      },
    );
    context.push(uri.toString());
  }

  /// 支払いカードタップ → TR0100（編集）
  static void goEditEventTransaction({
    required BuildContext context,
    required String eventId,
    required _EventPayment payment,
  }) {
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {
        'eventId': eventId,
        'transactionId': payment.id,
      },
    );
    context.push(uri.toString());
  }

  /// イベント削除（確認ダイアログ付き）
  static Future<void> confirmAndDeleteEvent({
    required BuildContext context,
    required String eventId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('イベントを削除'),
        content: const Text(
          'このイベントを削除しますか？\n'
          '登録済みの支払いも含めて元に戻せません。（モック段階の文言）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // モックデータから削除
    _mockEvents.removeWhere((e) => e.eventId == eventId);
    _mockPayments.removeWhere((p) => p.eventId == eventId);

    // 詳細画面を閉じて前の画面に戻る
    if (context.mounted) {
      context.pop();
    }
  }
}

/// ---------------------------
/// モックデータ
/// ---------------------------
class _EventLite {
  final String eventId;
  final String title;
  final DateTime date;
  final String location;

  const _EventLite({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
  });
}

/// 1件の支払い（イベント内トランザクション）のモック
class _EventPayment {
  final String id;
  final String eventId;
  final int amount;
  final String payerName;
  final DateTime recordedAt;

  const _EventPayment({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.payerName,
    required this.recordedAt,
  });
}

final _mockEvents = <_EventLite>[
  _EventLite(
    eventId: 'ev_001',
    title: '箱根旅行(2024/05)',
    date: DateTime(2024, 5, 3),
    location: '神奈川・箱根',
  ),
  _EventLite(
    eventId: 'ev_002',
    title: '夏フェス(2024/08)',
    date: DateTime(2024, 8, 20),
    location: '千葉・幕張',
  ),
];

final List<_EventPayment> _mockPayments = [
  _EventPayment(
    id: 'tx_001',
    eventId: 'ev_001',
    amount: 6000,
    payerName: 'A さん',
    recordedAt: DateTime(2024, 5, 3, 19, 30),
  ),
  _EventPayment(
    id: 'tx_002',
    eventId: 'ev_001',
    amount: 1200,
    payerName: 'B さん',
    recordedAt: DateTime(2024, 5, 3, 22, 10),
  ),
  _EventPayment(
    id: 'tx_003',
    eventId: 'ev_001',
    amount: 4500,
    payerName: 'C さん',
    recordedAt: DateTime(2024, 5, 4, 12, 15),
  ),
  _EventPayment(
    id: 'tx_004',
    eventId: 'ev_002',
    amount: 8000,
    payerName: 'みき',
    recordedAt: DateTime(2024, 8, 20, 18, 0),
  ),
];

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

String _fmtDateTime(DateTime d) {
  final date =
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}