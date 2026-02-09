import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/core/extensions/date_time_extension.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_message_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
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
/// ※ この画面から借用書には遷移しない
class Ev0200EventDetailScreen extends ConsumerStatefulWidget {
  const Ev0200EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<Ev0200EventDetailScreen> createState() =>
      _Ev0200EventDetailScreenState();
}

class _Ev0200EventDetailScreenState
    extends ConsumerState<Ev0200EventDetailScreen> {
  bool _didShowReadError = false;

  void _handleReadError(Object error, StackTrace stackTrace) {
    if (_didShowReadError) return;
    _didShowReadError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final err = toAppError(error, stackTrace);
      await showAppErrorDialog(context: context, error: err);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.eventId;
    if (eventId.isEmpty) {
      return _EventErrorView(
        title: 'イベントしょうさい',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    EventDetail? detail;
    try {
      detail = ref.watch(eventDetailProvider(eventId));
    } catch (e, st) {
      _handleReadError(e, st);
      return _EventErrorView(
        title: 'イベントしょうさい',
        message: AppMessages.dialog(AppMessageId.s004).message,
        onBack: () => context.go('/ev0100'),
      );
    }
    if (detail == null) {
      return _EventErrorView(
        title: 'イベントしょうさい',
        message: 'イベントが見つかりません。',
        onBack: () => context.go('/ev0100'),
      );
    }
    final eventMeta = detail.meta;
    final eventTitle = eventMeta.title;

    final payments = detail.transactions;
    final memberIds = _collectParticipantIds(eventMeta, payments);
    final memberNames = memberIds
        .map((id) => ref.watch(userDisplayNameProvider(id)))
        .toList(growable: false);
    final memberText = memberNames.isEmpty ? 'なし' : memberNames.join('　');

    final theme = Theme.of(context);
    final totalAmount = payments
        .where((p) => p.type == TxType.expense)
        .fold<int>(0, (sum, p) => sum + p.totalAmount);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/ev0100');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/ev0100'),
          ),
          title: Text(
            eventTitle.isEmpty ? 'イベントしょうさい' : eventTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: AppTextSizes.title,
              fontWeight: AppFontWeights.appBarTitle,
            ),
          ),
          centerTitle: true,
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
              memberText: memberText,
              onMembersPressed: () =>
                  _Controller.goMembers(context: context, eventId: eventId),
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
                fontSize: AppTextSizes.section,
                fontWeight: AppFontWeights.sectionTitle,
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
                    fontSize: AppTextSizes.body,
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
    return OutlinedButton(
      onPressed: onPressed,
      style: AppButtonStyles.addCircle,
      child: const Icon(Icons.add, size: 26),
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

  /// メンバー一覧 → EV0300
  static void goMembers({
    required BuildContext context,
    required String eventId,
  }) {
    context.pushNamed('EV0300', pathParameters: {'eventId': eventId});
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
    await showAppMessageDialog(
      context: context,
      messageId: AppMessageId.ev0200_001,
      closeOnDestructiveSuccess: false,
      onDestructive: () async {
        await ref.read(eventMetaListProvider.notifier).deleteEventMeta(eventId);
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        GoRouter.of(context).go('/ev0100');
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.theme,
    required this.totalAmount,
    required this.memberText,
    required this.onMembersPressed,
  });

  final ThemeData theme;
  final int totalAmount;
  final String memberText;
  final VoidCallback onMembersPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryListRow(
            label: 'ごうけい',
            value: totalAmount.toAmountWithUnit(AppStrings.amountUnit),
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.label,
            ),
          ),
          const Divider(height: 12, color: AppColors.listBorder),
          _SummaryListRow(
            label: 'めんばー',
            value: memberText,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.label,
            ),
            showArrow: true,
            onTap: onMembersPressed,
          ),
        ],
      ),
    );
  }
}

class _SummaryListRow extends StatelessWidget {
  const _SummaryListRow({
    required this.label,
    required this.value,
    required this.textStyle,
    this.onTap,
    this.showArrow = false,
  });

  final String label;
  final String value;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: AppTextSizes.small,
              fontWeight: AppFontWeights.label,
              color: AppColors.iconDefault,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: textStyle,
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.iconDefault,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
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
          backgroundColor: AppColors.secondaryActionFill,
          foregroundColor: AppColors.secondaryActionText,
          side: const BorderSide(
            color: AppColors.secondaryActionBorder,
            width: 1.2,
          ),
          shape: const StadiumBorder(),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        icon: const Icon(
          Icons.payments,
          size: 18,
          color: AppColors.secondaryActionText,
        ),
        label: Text(
          'せいさんする',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.label,
            color: AppColors.secondaryActionText,
          ),
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
            _PaymentRow(transaction: p, theme: theme, onTap: () => onTap(p)),
            if (index != payments.length - 1)
              const Divider(
                height: 1,
                thickness: 0.8,
                color: AppColors.listBorder,
              ),
          ],
        );
      }),
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({
    required this.transaction,
    required this.theme,
    required this.onTap,
  });

  final Transaction transaction;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.type == TxType.expense;
    final fromName = transaction.fromUserId == null
        ? '???'
        : ref.watch(userDisplayNameProvider(transaction.fromUserId!));
    final toName = transaction.toUserId == null
        ? '???'
        : ref.watch(userDisplayNameProvider(transaction.toUserId!));
    final payerName = transaction.paidBy == null
        ? '???'
        : ref.watch(userDisplayNameProvider(transaction.paidBy!));
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
                      fontSize: AppTextSizes.section,
                      fontWeight: AppFontWeights.listTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isExpense
                            ? '$payerName   ${transaction.date.toMdSlash()}'
                            : '$fromName → $toName   ${transaction.date.toMdSlash()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppTextSizes.small,
                          color: theme.hintColor,
                          fontWeight: AppFontWeights.listSubtitle,
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
                  transaction.totalAmount.toAmountWithUnit(
                    AppStrings.amountUnit,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: AppTextSizes.section,
                    fontWeight: AppFontWeights.listTitle,
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: AppTextSizes.title,
              fontWeight: AppFontWeights.appBarTitle,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: AppTextSizes.body),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onBack, child: const Text('もどる')),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _collectParticipantIds(
  EventMeta meta,
  List<Transaction> transactions,
) {
  final ids = <String>[];
  final seen = <String>{};

  void addIfMissing(String id) {
    if (id.isEmpty) return;
    if (seen.add(id)) ids.add(id);
  }

  for (final id in meta.participantIds) {
    addIfMissing(id);
  }

  for (final tx in transactions) {
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      if (paidBy != null) addIfMissing(paidBy);
      final shares = tx.shares;
      if (shares != null) {
        for (final id in shares.keys) {
          addIfMissing(id);
        }
      }
    } else {
      if (tx.fromUserId != null) addIfMissing(tx.fromUserId!);
      if (tx.toUserId != null) addIfMissing(tx.toUserId!);
    }
  }

  return ids;
}
