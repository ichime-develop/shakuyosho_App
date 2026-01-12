import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/data/mock/event_mock.dart' as event_mock;
import 'package:shakuyousho_app/domain/models/event_models.dart';

class EventState {
  EventState({
    required this.events,
    required this.transactions,
  });

  final List<EventSummary> events;
  final List<EventTransaction> transactions;

  EventState copyWith({
    List<EventSummary>? events,
    List<EventTransaction>? transactions,
  }) {
    return EventState(
      events: events ?? this.events,
      transactions: transactions ?? this.transactions,
    );
  }
}

class EventStateNotifier extends StateNotifier<EventState> {
  EventStateNotifier()
      : super(
          EventState(
            events: _mockEvents,
            transactions: _mockTxs,
          ),
        );

  List<EventSummary> get allEvents => state.events;

  List<EventSummary> get ongoingEvents {
    return state.events
        .where((e) => !e.isSettled)
        .toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  }

  List<EventSummary> get recentFinishedEvents {
    return state.events
        .where((e) => e.isSettled)
        .toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
  }

  List<EventTransaction> getTransactionsByEvent(String eventId) {
    return state.transactions
        .where((t) => t.eventId == eventId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void upsertTransaction(EventTransaction tx) {
    final txs = [...state.transactions];
    final index = txs.indexWhere((t) => t.id == tx.id);
    if (index == -1) {
      txs.add(tx);
    } else {
      txs[index] = tx;
    }
    final events = _recalculateEvent(tx.eventId, txs);
    state = state.copyWith(events: events, transactions: txs);
  }

  void deleteTransaction(String txId) {
    EventTransaction? target;
    for (final t in state.transactions) {
      if (t.id == txId) {
        target = t;
        break;
      }
    }
    final txs =
        state.transactions.where((t) => t.id != txId).toList(growable: false);
    final events =
        target == null ? state.events : _recalculateEvent(target.eventId, txs);
    state = state.copyWith(events: events, transactions: txs);
  }

  void upsertEvent(EventSummary event) {
    final events = [...state.events];
    final index = events.indexWhere((e) => e.id == event.id);
    if (index == -1) {
      events.add(event);
    } else {
      events[index] = event;
    }
    state = state.copyWith(events: events);
  }

  void deleteEvent(String eventId) {
    final events =
        state.events.where((e) => e.id != eventId).toList(growable: false);
    final txs =
        state.transactions.where((t) => t.eventId != eventId).toList(growable: false);
    state = state.copyWith(events: events, transactions: txs);
  }

  List<EventSummary> _recalculateEvent(
    String eventId,
    List<EventTransaction> txs,
  ) {
    final events = [...state.events];
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return events;
    final txsForEvent =
        txs.where((transaction) => transaction.eventId == eventId).toList();
    final total =
        txsForEvent.fold<int>(0, (sum, t) => sum + t.totalAmount);
    final updatedSummary = events[idx].copyWith(
      lastUpdatedAt: DateTime.now(),
      totalUnsettledAmount: total,
    );
    events[idx] = updatedSummary;
    return events;
  }
}

final eventStateProvider =
    StateNotifierProvider<EventStateNotifier, EventState>((ref) {
  return EventStateNotifier();
});

// イベントサマリー / 取引のモック
final List<EventSummary> _mockEvents =
    List<EventSummary>.from(event_mock.mockEvents);

final List<EventTransaction> _mockTxs =
    List<EventTransaction>.from(event_mock.mockTransactions);
