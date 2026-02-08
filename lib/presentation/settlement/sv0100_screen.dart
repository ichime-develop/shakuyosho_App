import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';

import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

/// SV0100: イベント精算画面
/// - メンバーの支払総額と負担割合からネット残高を算出
/// - "誰が誰へいくら払うか" の最小送金案（ヒューリスティック）を提示
/// - 各提案から「取引へ(TR0100)」へ遷移（モック）
/// - ※ この画面から借用書には遷移しない
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
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          fontSize: AppTextSizes.title,
          fontWeight: AppFontWeights.appBarTitle,
        ),
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
                  fontSize: AppTextSizes.body,
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
          onPressed: () => _goApplySettlement(transfers),
          style: AppButtonStyles.primaryPill,
          icon: const Icon(Icons.check_circle, size: 20),
          label: Text(
            'せいさんかんりょう',
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.label,
              color: AppColors.primaryActionText,
            ),
          ),
        ),
      ),
    );
  }

  // _goLb は削除（借用書はイベント起点では発行しない）

  void _goTx(SettlementInstruction t) {
    final eventId = widget.eventId;
    context.push(
      '/tr0100/$eventId?mode=repayment&toUserId=${t.toUserId}&amount=${t.amount}',
    );
  }

  void _goCreateAllLb(List<SettlementInstruction> list) {
    // 借用書は個人起点のみのため、この機能は廃止
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('借用書は友だち詳細画面から発行してください')));
  }

  void _goApplySettlement(List<SettlementInstruction> list) {
    final eventId = widget.eventId;
    final meta = ref.read(eventMetaProvider(eventId));
    if (meta != null) {
      ref
          .read(eventMetaListProvider.notifier)
          .upsertEventMeta(
            meta.copyWith(
              status: EventStatus.settled,
              updatedAt: DateTime.now(),
            ),
          );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('かくてい')));
    context.go('/ev0100');
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
            color: AppColors.secondaryActionFill,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.handshake,
            color: AppColors.secondaryActionText,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'けっか',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: AppTextSizes.section,
            fontWeight: AppFontWeights.sectionTitle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'だれがだれにいくらはらうか\nまとめておいたよ',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: AppTextSizes.small,
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }
}

class _TransferList extends ConsumerWidget {
  const _TransferList({required this.transfers});
  final List<SettlementInstruction> transfers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.listBorder),
          bottom: const BorderSide(color: AppColors.listBorder),
        ),
      ),
      child: Column(
        children: List.generate(transfers.length, (index) {
          final t = transfers[index];
          final fromName = ref.watch(userDisplayNameProvider(t.fromUserId));
          final toName = ref.watch(userDisplayNameProvider(t.toUserId));
          return Column(
            children: [
              _TransferRow(
                amount: t.amount,
                fromName: fromName,
                toName: toName,
              ),
              if (index != transfers.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.6,
                  color: AppColors.listBorder,
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
                  amount.toYenSymbol(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: AppTextSizes.section,
                    fontWeight: AppFontWeights.listTitle,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.listBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.iconDefault,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'へ はらう',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    fontWeight: AppFontWeights.label,
                    color: AppColors.iconDefault,
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
        ? AppColors.lendAmount
        : AppColors.borrowAmount;
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: AppTextSizes.section,
                    fontWeight: AppFontWeights.label,
                    color: baseColor,
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
                    color: isReceiver ? baseColor : AppColors.borrowAmount,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: AppTextSizes.tiny,
              fontWeight: AppFontWeights.label,
            ),
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
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: AppTextSizes.title,
                  fontWeight: AppFontWeights.appBarTitle,
                ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onBack, child: const Text('EV0100にもどる')),
            ],
          ),
        ),
      ),
    );
  }
}
