import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  List<EventSummary> get ongoingEvents =>
      state.events.where((e) => !e.isSettled).toList();

  List<EventSummary> get recentFinishedEvents =>
      state.events.where((e) => e.isSettled).toList();

  List<EventTransaction> getTransactionsByEvent(String eventId) =>
      state.transactions.where((t) => t.eventId == eventId).toList();

  void upsertTransaction(EventTransaction tx) {
    final txs = [...state.transactions];
    final index = txs.indexWhere((t) => t.id == tx.id);
    if (index == -1) {
      txs.add(tx);
    } else {
      txs[index] = tx;
    }
    state = state.copyWith(transactions: txs);
  }

  void deleteTransaction(String txId) {
    final txs =
        state.transactions.where((t) => t.id != txId).toList(growable: false);
    state = state.copyWith(transactions: txs);
  }
}

final eventStateProvider =
    StateNotifierProvider<EventStateNotifier, EventState>((ref) {
  return EventStateNotifier();
});

final _mockEvents = <EventSummary>[
  EventSummary(
    id: 'ev-hakone-2025-01',
    title: 'はこねりょこう',
    isSettled: false,
    members: ['A さん', 'B さん', 'C さん'],
    lastUpdatedAt: DateTime(2025, 10, 20),
    totalUnsettledAmount: 12000,
  ),
  EventSummary(
    id: 'ev-onsen-2024-12',
    title: 'おんせんかい',
    isSettled: true,
    members: ['A さん', 'D さん'],
    lastUpdatedAt: DateTime(2024, 12, 5),
    totalUnsettledAmount: 0,
  ),
];

final _mockTxs = <EventTransaction>[
  EventTransaction(
    id: 'tx-1',
    eventId: 'ev-hakone-2025-01',
    title: 'よるごはん',
    paidBy: 'A さん',
    totalAmount: 8000,
    shares: {
      'A さん': 4000,
      'B さん': 4000,
      'C さん': 0,
    },
    createdAt: DateTime(2025, 10, 18, 19, 30),
  ),
  EventTransaction(
    id: 'tx-2',
    eventId: 'ev-hakone-2025-01',
    title: 'あさごはん',
    paidBy: 'B さん',
    totalAmount: 4000,
    shares: {
      'A さん': 2000,
      'B さん': 2000,
      'C さん': 0,
    },
    createdAt: DateTime(2025, 10, 19, 8, 0),
  ),
];
