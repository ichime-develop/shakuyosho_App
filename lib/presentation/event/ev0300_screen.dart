import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

/// EV0300: イベント参加メンバー一覧
class Ev0300EventMembersScreen extends ConsumerStatefulWidget {
  const Ev0300EventMembersScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<Ev0300EventMembersScreen> createState() =>
      _Ev0300EventMembersScreenState();
}

class _Ev0300EventMembersScreenState
    extends ConsumerState<Ev0300EventMembersScreen> {
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
        title: 'めんばー',
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
        title: 'めんばー',
        message: AppMessages.dialog(AppMessageId.s004).message,
        onBack: () => context.go('/ev0100'),
      );
    }
    if (detail == null) {
      return _EventErrorView(
        title: 'めんばー',
        message: 'イベントが見つかりません。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final memberIds = _collectParticipantIds(detail);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'めんばー',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: AppTextSizes.title,
            fontWeight: AppFontWeights.appBarTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            detail.meta.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: AppTextSizes.section,
              fontWeight: AppFontWeights.sectionTitle,
            ),
          ),
          const SizedBox(height: 12),
          if (memberIds.isEmpty)
            Text(
              'メンバーがいないよ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.body,
                color: theme.hintColor,
              ),
            )
          else
            Column(
              children: List.generate(memberIds.length, (index) {
                final id = memberIds[index];
                final name = ref.watch(userDisplayNameProvider(id));
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.listSubtitle,
                        ),
                      ),
                    ),
                    if (index != memberIds.length - 1)
                      const Divider(height: 1, color: AppColors.listBorder),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}

List<String> _collectParticipantIds(EventDetail detail) {
  final ids = <String>[];
  final seen = <String>{};

  void addIfMissing(String id) {
    if (id.isEmpty) return;
    if (seen.add(id)) ids.add(id);
  }

  for (final id in detail.meta.participantIds) {
    addIfMissing(id);
  }

  for (final tx in detail.transactions) {
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                    ),
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
