import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/data/mock/event_mock.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';

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
    final eventId = qp['eventId'] ?? mockEvents.first.id;

    final event = mockEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => mockEvents.first,
    );

    // 本来は eventId に紐づく支払い一覧を Provider から取得する想定
    final payments =
        mockTransactions.where((p) => p.eventId == event.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 新しい順

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
            tooltip: 'イベントをけす',
            onPressed: () => _Controller.confirmAndDeleteEvent(
              context: context,
              eventId: event.id,
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
                      'このイベントのおしはらいはまだないよ。\n「ついか」ボタンからメモできるよ。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: InkWell(
                          onTap: () => _Controller.goEditEventTransaction(
                            context: context,
                            eventId: event.id,
                            payment: p,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 左側: タイトル + サブ情報
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'メモしたひ: ${_fmtDateTime(p.createdAt)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: theme.hintColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'はらったひと: ${p.paidBy}',
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
                                      _fmtYen(p.totalAmount),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                                      tooltip: 'おしはらいをけす',
                                      onPressed: () =>
                                          _onDeletePayment(context, p.id),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _Controller.goAddEventTransaction(
                      context: context,
                      eventId: event.id,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('ついか'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _Controller.goSettlement(
                      context: context,
                      eventId: event.id,
                    ),
                    child: const Text('おかねをまとめる'),
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
        title: const Text('おしはらいをけす'),
        content: const Text(
          'このおしはらいをけしていい？\n'
          'もとにもどせないよ。（モック）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('けす'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Mock deletion
    // In mock file this would remove, but shared mock is immutable here; rebuild not required.
    // If desired, modify mockTransactions in memory for testing.
    // _mockPayments.removeWhere((p) => p.id == paymentId);

    // Rebuild UI (force refresh)
    (context as Element).markNeedsBuild();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('おしはらいをけしたよ（モック）')));
  }
}

class _Controller {
  /// 清算ボタン → SV0100
  static void goSettlement({
    required BuildContext context,
    required String eventId,
  }) {
    final uri = Uri(path: '/sv0100', queryParameters: {'eventId': eventId});
    context.push(uri.toString());
  }

  /// 追加ボタン → TR0100（新規）
  static void goAddEventTransaction({
    required BuildContext context,
    required String eventId,
  }) {
    final uri = Uri(path: '/tr0100', queryParameters: {'eventId': eventId});
    context.push(uri.toString());
  }

  /// 支払いカードタップ → TR0100（編集）
  static void goEditEventTransaction({
    required BuildContext context,
    required String eventId,
    required EventTransaction payment,
  }) {
    final uri = Uri(
      path: '/tr0100',
      queryParameters: {'eventId': eventId, 'transactionId': payment.id},
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
        title: const Text('イベントをけす'),
        content: const Text(
          'このイベントをけしていい？\n'
          'メモしたおしはらいももとにもどらないよ。（モック）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('けす'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // モックデータから削除
    // Note: shared mock lists are static fixtures. In integration tests you'd replace providers.
    // Leaving them as-is for now.

    // 詳細画面を閉じて前の画面に戻る
    if (context.mounted) {
      context.pop();
    }
  }
}

// Using shared mock lists from lib/data/mock/event_mock.dart

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
