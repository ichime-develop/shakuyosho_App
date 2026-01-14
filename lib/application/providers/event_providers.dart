import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/data/mock/event_mock.dart' as event_mock;
import 'package:shakuyousho_app/data/mock/transactions_mock.dart'
    as transactions_mock;
import 'package:shakuyousho_app/data/repository/event_repository.dart';
import 'package:shakuyousho_app/data/repository/transaction_repository.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

class EventState {
  EventState({required this.events, required this.transactions});

  final List<EventSummary> events;
  final List<Transaction> transactions;

  EventState copyWith({
    List<EventSummary>? events,
    List<Transaction>? transactions,
  }) {
    return EventState(
      events: events ?? this.events,
      transactions: transactions ?? this.transactions,
    );
  }
}

class EventStateNotifier extends StateNotifier<EventState> {
  EventStateNotifier()
    : super(EventState(events: _buildEventSummaries(), transactions: _mockTxs));

  List<EventSummary> get allEvents => state.events;

  List<EventSummary> get ongoingEvents {
    return state.events.where((e) => !e.isSettled).toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  }

  List<EventSummary> get recentFinishedEvents {
    return state.events.where((e) => e.isSettled).toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  }

  List<Transaction> getTransactionsByEvent(String eventId) {
    return state.transactions
        .where((t) => t.eventId == eventId && t.deletedAt == null)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void upsertTransaction(Transaction tx) {
    final txs = [...state.transactions];
    final index = txs.indexWhere((t) => t.id == tx.id);
    final now = DateTime.now();
    final updatedTx = tx.updatedAt == null ? tx.copyWith(updatedAt: now) : tx;
    if (index == -1) {
      txs.add(updatedTx);
    } else {
      txs[index] = updatedTx;
    }
    final events = _buildEventSummaries(txs: txs);
    state = state.copyWith(events: events, transactions: txs);
  }

  void deleteTransaction(String txId) {
    final now = DateTime.now();
    final txs = state.transactions.map((t) {
      if (t.id != txId) return t;
      return t.copyWith(deletedAt: now, updatedAt: now);
    }).toList(growable: false);
    final events = _buildEventSummaries(txs: txs);
    state = state.copyWith(events: events, transactions: txs);
  }

  void upsertEvent(EventSummary event) {
    final index = _eventSeeds.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      _eventSeeds.add(event);
    } else {
      _eventSeeds[index] = event;
    }
    state = state.copyWith(events: _buildEventSummaries(txs: state.transactions));
  }

  void deleteEvent(String eventId) {
    _eventSeeds.removeWhere((e) => e.id == eventId);
    final txs = state.transactions
        .where((t) => t.eventId != eventId)
        .toList(growable: false);
    state = state.copyWith(events: _buildEventSummaries(txs: txs), transactions: txs);
  }
}

final eventStateProvider =
    StateNotifierProvider<EventStateNotifier, EventState>((ref) {
      return EventStateNotifier();
    });

// イベントサマリー / 取引のモック
final EventRepository _eventRepo = MockEventRepository(
  List<EventSummary>.from(event_mock.mockEvents),
);

final TransactionRepository _txRepo = MockTransactionRepository(
  List<Transaction>.from(transactions_mock.mockDomainTransactions),
);

final List<EventSummary> _eventSeeds = List<EventSummary>.from(
  _eventRepo.getAllEvents(),
);

final List<Transaction> _mockTxs = List<Transaction>.from(
  _txRepo.getAllTransactions(),
);

List<EventSummary> _buildEventSummaries({List<Transaction>? txs}) {
  final source = txs ?? _mockTxs;
  return _eventSeeds
      .map((seed) => _deriveEventSummary(seed, source))
      .toList(growable: false);
}

EventSummary _deriveEventSummary(
  EventSummary seed,
  List<Transaction> txs,
) {
  final eventTxs = txs
      .where((t) => t.eventId == seed.id && t.deletedAt == null)
      .toList(growable: false);
  final participantIds = _mergeParticipantIds(seed.participantIds, eventTxs);
  final lastUpdatedAt = _latestDate(eventTxs, seed.lastUpdatedAt);
  final net = _calcNetBalances(eventTxs, participantIds);
  final totalUnsettled =
      net.values.where((v) => v > 0).fold<int>(0, (p, v) => p + v);
  return seed.copyWith(
    participantIds: participantIds,
    lastUpdatedAt: lastUpdatedAt,
    totalUnsettledAmount: totalUnsettled,
  );
}

List<String> _mergeParticipantIds(
  List<String> base,
  List<Transaction> txs,
) {
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

DateTime _latestDate(List<Transaction> txs, DateTime fallback) {
  if (txs.isEmpty) return fallback;
  var latest = txs.first.date;
  for (final tx in txs.skip(1)) {
    if (tx.date.isAfter(latest)) {
      latest = tx.date;
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
      net.update(paidBy, (v) => v + tx.totalAmount,
          ifAbsent: () => tx.totalAmount);
      for (final entry in shares.entries) {
        net.update(entry.key, (v) => v - entry.value,
            ifAbsent: () => -entry.value);
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
