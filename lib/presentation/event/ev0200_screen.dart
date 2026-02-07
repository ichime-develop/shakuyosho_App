import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';

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

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId.isEmpty) {
      return _EventErrorView(
        title: 'EV0200',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final detail = ref.watch(eventDetailProvider(eventId));
    if (detail == null) {
      return _EventErrorView(
        title: 'EV0200',
        message: 'イベントが見つかりません。',
        onBack: () => context.go('/ev0100'),
      );
    }
    final eventMeta = detail.meta;
    final eventTitle = eventMeta.title;

    final payments = detail.transactions;

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
              icon: const Icon(CupertinoIcons.trash),
              tooltip: 'イベントをけす',
              onPressed: () => _Controller.confirmAndDeleteEvent(
                context: context,
                ref: ref,
                eventId: eventId,
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
              count: payments.length,
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              onPressed: () =>
                  _Controller.goSettlement(context: context, eventId: eventId),
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
                  eventId: eventId,
                  payment: p,
                ),
              ),
          ],
        ),
        floatingActionButton: _CreateFab(
          onPressed: () => _Controller.goAddEventTransaction(
            context: context,
            eventId: eventId,
          ),
        ),
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF13EC80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        elevation: 8,
      ),
      icon: const Icon(Icons.add, size: 28, color: Color(0xFF102219)),
      label: const Text(
        'あたらしくつくる',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102219)),
      ),
    );
  }
}

class _Controller {
  /// 清算ボタン → SV0100
  static void goSettlement({
    required BuildContext context,
    required String eventId,
  }) {
    context.push('/sv0100/$eventId');
  }

  /// 追加ボタン → TR0100（新規）
  static void goAddEventTransaction({
    required BuildContext context,
    required String eventId,
  }) {
    context.push('/tr0100/$eventId');
  }

  /// 支払いカードタップ → TR0100（編集）
  static void goEditEventTransaction({
    required BuildContext context,
    required String eventId,
    required Transaction payment,
  }) {
    final uri = Uri(
      path: '/tr0100/$eventId',
      queryParameters: {'transactionId': payment.id},
    );
    context.push(uri.toString());
  }

  /// イベント削除（確認ダイアログ付き）
  static Future<void> confirmAndDeleteEvent({
    required BuildContext context,
    required WidgetRef ref,
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
    ref.read(eventMetaListProvider.notifier).deleteEventMeta(eventId);

    // 詳細画面を閉じて前の画面に戻る
    if (context.mounted) {
      context.pop();
    }
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.theme,
    required this.totalAmount,
    required this.count,
  });

  final ThemeData theme;
  final int totalAmount;
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
            unit: AppStrings.amountUnit,
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
  });

  final List<Transaction> payments;
  final ThemeData theme;
  final void Function(Transaction) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(payments.length, (index) {
        final p = payments[index];
        return Column(
          children: [
            _PaymentRow(
              transaction: p,
              theme: theme,
              onTap: () => onTap(p),
            ),
            if (index != payments.length - 1)
              Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
          ],
        );
      }),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.transaction,
    required this.theme,
    required this.onTap,
  });

  final Transaction transaction;
  final ThemeData theme;
  final VoidCallback onTap;

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
                  AppStrings.amountWithUnitInt(transaction.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
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
              TextButton(onPressed: onBack, child: const Text('EV0100にもどる')),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtMonthDay(DateTime d) =>
    '${d.month}/${d.day.toString().padLeft(2, '0')}';
