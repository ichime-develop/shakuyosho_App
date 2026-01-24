import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/data/mock/event_meta_mock.dart'
    as event_meta_mock;
import 'package:shakuyousho_app/data/mock/threads_mock.dart' as threads_mock;
import 'package:shakuyousho_app/infrastructure/mock/mock_transaction_mapper.dart'
    as mock_transaction_mapper;
import 'package:shakuyousho_app/infrastructure/repositories/mock_event_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/mock_thread_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/mock_transaction_repository.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';

class EventDetail {
  const EventDetail({required this.meta, required this.transactions});
  final EventMeta meta;
  final List<Transaction> transactions;
}

class EventDerivedSummary {
  const EventDerivedSummary({
    required this.participantIds,
    required this.lastUpdatedAt,
    required this.isSettled,
  });

  final List<String> participantIds;
  final DateTime lastUpdatedAt;
  final bool isSettled;
}

class EventMetaListNotifier extends StateNotifier<List<EventMeta>>
    implements EventRepository {
  EventMetaListNotifier({
    required EventRepository eventRepository,
    required List<EventMeta> initialMetas,
  }) : _eventRepository = eventRepository,
       super(List<EventMeta>.from(initialMetas));

  final EventRepository _eventRepository;

  @override
  List<EventMeta> getAllEventMetas() => List.unmodifiable(state);

  @override
  EventMeta? getEventMetaById(String eventId) {
    for (final meta in state) {
      if (meta.id == eventId) return meta;
    }
    return null;
  }

  @override
  void upsertEventMeta(EventMeta meta) {
    _eventRepository.upsertEventMeta(meta);
    final updated = [...state];
    final index = updated.indexWhere((m) => m.id == meta.id);
    if (index == -1) {
      updated.add(meta);
    } else {
      updated[index] = meta;
    }
    state = updated;
  }

  @override
  void deleteEventMeta(String eventId) {
    _eventRepository.deleteEventMeta(eventId);
    state = state.where((meta) => meta.id != eventId).toList(growable: false);
  }
}

class TransactionListNotifier extends StateNotifier<List<Transaction>>
    implements TransactionRepository {
  TransactionListNotifier({
    required TransactionRepository transactionRepository,
    required List<Transaction> initialTransactions,
  }) : _transactionRepository = transactionRepository,
       super(List<Transaction>.from(initialTransactions));

  final TransactionRepository _transactionRepository;

  @override
  List<Transaction> getByEventId(String eventId) {
    return _transactionRepository.getByEventId(eventId);
  }

  @override
  void upsert(Transaction tx) {
    _transactionRepository.upsert(tx);
    final updated = [...state];
    final index = updated.indexWhere((t) => t.id == tx.id);
    if (index == -1) {
      updated.add(tx);
    } else {
      updated[index] = tx;
    }
    state = updated;
  }

  @override
  void delete(String txId) {
    _transactionRepository.delete(txId);
    final now = DateTime.now();
    final updated = state
        .map((t) {
          if (t.id != txId) return t;
          return t.copyWith(deletedAt: now, updatedAt: now);
        })
        .toList(growable: false);
    state = updated;
  }
}

class ThreadListNotifier extends StateNotifier<List<Thread>>
    implements ThreadRepository {
  ThreadListNotifier({
    required ThreadRepository threadRepository,
    required List<Thread> initialThreads,
  }) : _threadRepository = threadRepository,
       super(List<Thread>.from(initialThreads));

  final ThreadRepository _threadRepository;

  @override
  List<Thread> getAll() => List.unmodifiable(state);

  @override
  Thread? getById(String threadId) {
    for (final thread in state) {
      if (thread.id == threadId) return thread;
    }
    return null;
  }

  @override
  void upsert(Thread thread) {
    _threadRepository.upsert(thread);
    final updated = [...state];
    final index = updated.indexWhere((t) => t.id == thread.id);
    if (index == -1) {
      updated.add(thread);
    } else {
      updated[index] = thread;
    }
    state = updated;
  }
}

final List<EventMeta> _initialEventMetas = List<EventMeta>.from(
  event_meta_mock.mockEventMetas,
);
final List<Transaction> _initialTransactions = List<Transaction>.from(
  mock_transaction_mapper.mockDomainTransactions,
);
final List<Thread> _initialThreads = List<Thread>.from(
  threads_mock.mockThreads,
);

final EventRepository _eventRepo = MockEventRepository(
  initialMetas: _initialEventMetas,
);
final TransactionRepository _txRepo = MockTransactionRepository(
  _initialTransactions,
);
final ThreadRepository _threadRepo = MockThreadRepository(_initialThreads);

// Repository providers
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return ref.read(eventMetaListProvider.notifier);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ref.read(transactionListProvider.notifier);
});

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ref.read(threadListProvider.notifier);
});

// State providers
final eventMetaListProvider =
    StateNotifierProvider<EventMetaListNotifier, List<EventMeta>>((ref) {
      return EventMetaListNotifier(
        eventRepository: _eventRepo,
        initialMetas: _initialEventMetas,
      );
    });

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, List<Transaction>>((ref) {
      return TransactionListNotifier(
        transactionRepository: _txRepo,
        initialTransactions: _initialTransactions,
      );
    });

final threadListProvider =
    StateNotifierProvider<ThreadListNotifier, List<Thread>>((ref) {
      return ThreadListNotifier(
        threadRepository: _threadRepo,
        initialThreads: _initialThreads,
      );
    });

// Derived providers
final eventMetaProvider = Provider.family<EventMeta?, String>((ref, eventId) {
  final metas = ref.watch(eventMetaListProvider);
  for (final meta in metas) {
    if (meta.id == eventId && meta.deletedAt == null) return meta;
  }
  return null;
});

final transactionsByEventProvider = Provider.family<List<Transaction>, String>((
  ref,
  eventId,
) {
  final txs = ref.watch(transactionListProvider);
  final filtered = txs
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList(growable: false);
  final sorted = List<Transaction>.from(filtered)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

final eventDetailProvider = Provider.family<EventDetail?, String>((
  ref,
  eventId,
) {
  final meta = ref.watch(eventMetaProvider(eventId));
  if (meta == null) return null;

  // Watch transaction state so detail updates after writes.
  ref.watch(transactionListProvider);
  final txs = List<Transaction>.from(
    ref.read(transactionRepositoryProvider).getByEventId(eventId),
  )..sort((a, b) => b.date.compareTo(a.date));
  return EventDetail(meta: meta, transactions: txs);
});

final settlementProvider = Provider.family<SettlementSummary?, String>((
  ref,
  eventId,
) {
  final detail = ref.watch(eventDetailProvider(eventId));
  if (detail == null) return null;
  return computeSettlement(
    detail.transactions,
    eventId: eventId,
    participantIds: detail.meta.participantIds,
  );
});

EventDerivedSummary deriveEventSummary(EventMeta meta, List<Transaction> txs) {
  final participantIds = _mergeParticipantIds(meta.participantIds, txs);
  final lastUpdatedAt = _latestUpdatedAt(meta.updatedAt, txs);
  final net = _calcNetBalances(txs, participantIds);
  final isSettled = txs.isNotEmpty && net.values.every((v) => v == 0);
  return EventDerivedSummary(
    participantIds: participantIds,
    lastUpdatedAt: lastUpdatedAt,
    isSettled: isSettled,
  );
}

SettlementSummary computeSettlement(
  List<Transaction> txs, {
  required String eventId,
  List<String>? participantIds,
}) {
  final members = participantIds ?? _mergeParticipantIds(const [], txs);
  final balances = _calcNetBalances(txs, members);
  final instructions = _simplifyBalances(balances);
  return SettlementSummary(
    eventId: eventId,
    balancesByUserId: balances,
    instructions: instructions,
    generatedAt: DateTime.now(),
  );
}

List<String> _mergeParticipantIds(List<String> base, List<Transaction> txs) {
  final ids = <String>{...base};
  for (final tx in txs) {
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      if (paidBy != null) ids.add(paidBy);
      final shares = tx.shares;
      if (shares != null) ids.addAll(shares.keys);
    } else {
      if (tx.fromUserId != null) ids.add(tx.fromUserId!);
      if (tx.toUserId != null) ids.add(tx.toUserId!);
    }
  }
  return ids.toList(growable: false);
}

DateTime _latestUpdatedAt(DateTime metaUpdatedAt, List<Transaction> txs) {
  var latest = metaUpdatedAt;
  for (final tx in txs) {
    final candidate = tx.updatedAt ?? tx.date;
    if (candidate.isAfter(latest)) {
      latest = candidate;
    }
  }
  return latest;
}

Map<String, int> _calcNetBalances(
  List<Transaction> txs,
  List<String> memberIds,
) {
  final net = {for (final id in memberIds) id: 0};
  for (final tx in txs) {
    if (tx.deletedAt != null) continue;
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      final shares = tx.shares;
      if (paidBy == null || shares == null) continue;
      net.update(
        paidBy,
        (v) => v + tx.totalAmount,
        ifAbsent: () => tx.totalAmount,
      );
      for (final entry in shares.entries) {
        net.update(
          entry.key,
          (v) => v - entry.value,
          ifAbsent: () => -entry.value,
        );
      }
    } else {
      final fromUserId = tx.fromUserId;
      final toUserId = tx.toUserId;
      if (fromUserId == null || toUserId == null) continue;
      final amount = tx.repaymentAmount ?? tx.totalAmount;
      net.update(fromUserId, (v) => v + amount, ifAbsent: () => amount);
      net.update(toUserId, (v) => v - amount, ifAbsent: () => -amount);
    }
  }
  return net;
}

class _BalanceItem {
  _BalanceItem(this.userId, this.amount);
  final String userId;
  int amount;
}

List<SettlementInstruction> _simplifyBalances(Map<String, int> balances) {
  final creditors = <_BalanceItem>[];
  final debtors = <_BalanceItem>[];
  balances.forEach((userId, amount) {
    if (amount > 0) {
      creditors.add(_BalanceItem(userId, amount));
    } else if (amount < 0) {
      debtors.add(_BalanceItem(userId, -amount));
    }
  });

  final instructions = <SettlementInstruction>[];
  int i = 0;
  int j = 0;
  while (i < debtors.length && j < creditors.length) {
    final debtor = debtors[i];
    final creditor = creditors[j];
    final pay = debtor.amount < creditor.amount
        ? debtor.amount
        : creditor.amount;
    instructions.add(
      SettlementInstruction(
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amount: pay,
        currency: 'JPY',
      ),
    );
    debtor.amount -= pay;
    creditor.amount -= pay;
    if (debtor.amount == 0) i++;
    if (creditor.amount == 0) j++;
  }
  return instructions;
}

String generateId({required String prefix}) {
  final now = DateTime.now().toUtc();
  final timestamp = now.toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
  final rand = Random().nextInt(1000).toString().padLeft(3, '0');
  return '${prefix}_$timestamp$rand';
}
