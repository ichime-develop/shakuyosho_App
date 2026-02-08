import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

/// EV0300: イベント参加メンバー一覧
class Ev0300EventMembersScreen extends ConsumerWidget {
  const Ev0300EventMembersScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eventId.isEmpty) {
      return _EventErrorView(
        title: 'EV0300',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final detail = ref.watch(eventDetailProvider(eventId));
    if (detail == null) {
      return _EventErrorView(
        title: 'EV0300',
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
        title: const Text('EV0300 メンバー'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            detail.meta.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (memberIds.isEmpty)
            Text(
              'メンバーがいないよ',
              style: theme.textTheme.bodyMedium?.copyWith(
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
                      title: Text(name),
                    ),
                    if (index != memberIds.length - 1)
                      const Divider(height: 1),
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
