import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

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
  const Ev0200EventDetailScreen({super.key, required this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId == null || eventId!.isEmpty) {
      return _EventErrorView(
        title: 'EV0200',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final summaries = ref.watch(eventSummariesProvider);
    if (summaries.isEmpty) {
      return _EventErrorView(
        title: 'EV0200',
        message: 'イベントがありません。',
        onBack: () => context.go('/ev0100'),
      );
    }

    EventSummary? eventSummary;
    for (final summary in summaries) {
      if (summary.id == eventId) {
        eventSummary = summary;
        break;
      }
    }
    final eventSummaryResolved = eventSummary;
    if (eventSummaryResolved == null) {
      return _EventErrorView(
        title: 'EV0200',
        message: 'イベントが見つかりません。',
        onBack: () => context.go('/ev0100'),
      );
    }
    final eventMeta =
        ref.watch(eventMetaByIdProvider(eventSummaryResolved.id));
    final eventTitle = eventMeta?.title ?? eventSummaryResolved.title;

    final payments =
        ref.watch(transactionsByEventIdProvider(eventSummaryResolved.id));

    final theme = Theme.of(context);
    final totalAmount = payments
        .where((p) => p.type == TxType.expense)
        .fold<int>(0, (sum, p) => sum + p.totalAmount);

    return WillPopScope(
      onWillPop: () async {
        context.go('/ev0100');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/ev0100'),
          ),
          title: Text('EV0200 $eventTitle'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'イベントをけす',
              onPressed: () => _Controller.confirmAndDeleteEvent(
                context: context,
                eventId: eventSummaryResolved.id,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            _SummaryPanel(
              theme: theme,
              totalAmount: totalAmount,
              unsettled: eventSummaryResolved.totalUnsettledAmount,
              count: payments.length,
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              onPressed: () => _Controller.goSettlement(
                context: context,
                eventId: eventSummaryResolved.id,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'きろく',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'このイベントのおしはらいはまだないよ。\n「＋」ボタンからメモできるよ。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              )
            else
              _PaymentList(
                payments: payments,
                theme: theme,
                onTap: (p) => _Controller.goEditEventTransaction(
                  context: context,
                  eventId: eventSummaryResolved.id,
                  payment: p,
                ),
                onDelete: (p) => _onDeletePayment(ref, context, p.id),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _Controller.goAddEventTransaction(
            context: context,
            eventId: eventSummaryResolved.id,
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _onDeletePayment(
    WidgetRef ref,
    BuildContext context,
    String paymentId,
  ) async {
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
    // Delete via provider so other screens update
    ref.read(eventStateProvider.notifier).deleteTransaction(paymentId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('おしはらいをけしたよ')));
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
    required Transaction payment,
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.theme,
    required this.totalAmount,
    required this.unsettled,
    required this.count,
  });

  final ThemeData theme;
  final int totalAmount;
  final int unsettled;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'ごうけい',
            value: _fmtYen(totalAmount).replaceAll('¥', ''),
            unit: 'えん',
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            valueStyle: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 16),
          _SummaryRow(
            label: 'あなたがうけとる',
            value: _fmtYen(unsettled).replaceAll('¥', ''),
            unit: 'えん',
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            valueStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'きろく $count 件',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final String unit;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Row(
          children: [
            Text(value, style: valueStyle),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111814),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        icon: const Icon(Icons.payments, size: 18),
        label: const Text(
          'せいさんする',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.payments,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  final List<Transaction> payments;
  final ThemeData theme;
  final void Function(Transaction) onTap;
  final void Function(Transaction) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(payments.length, (index) {
          final p = payments[index];
          return Column(
            children: [
              _PaymentRow(
                transaction: p,
                theme: theme,
                onTap: () => onTap(p),
                onDelete: () => onDelete(p),
              ),
              if (index != payments.length - 1)
                Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
            ],
          );
        }),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.transaction,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  final Transaction transaction;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TxType.expense;
    final fromName = transaction.fromUserId == null
        ? '???'
        : displayNameOf(transaction.fromUserId!);
    final toName = transaction.toUserId == null
        ? '???'
        : displayNameOf(transaction.toUserId!);
    final payerName = transaction.paidBy == null
        ? '???'
        : displayNameOf(transaction.paidBy!);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpense
                            ? '$payerName • ${_fmtMonthDay(transaction.date)}'
                            : '$fromName → $toName • ${_fmtMonthDay(transaction.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.totalAmount}円',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusChip(
                      label: isExpense ? 'たてかえ' : 'へんさい',
                      color: isExpense
                          ? theme.colorScheme.primary
                          : Colors.orangeAccent,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'おしはらいをけす',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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

String _fmtMonthDay(DateTime d) =>
    '${d.month}/${d.day.toString().padLeft(2, '0')}';
