import 'package:shakuyousho_app/domain/models/event_models.dart';

import 'transactions_mock.dart';
import 'users_mock.dart';

class MockEvent {
  MockEvent({
    required this.summary,
    required this.memberUserIds,
    required this.transactions,
  });

  final EventSummary summary;
  final List<String> memberUserIds;
  final List<EventTransaction> transactions;
}

final List<MockEvent> _mockEventData = _buildMockEvents();

final List<EventSummary> mockEvents =
    _mockEventData.map((e) => e.summary).toList(growable: false);

final List<EventTransaction> mockTransactions =
    _mockEventData.expand((e) => e.transactions).toList(growable: false);

final Map<String, List<String>> mockEventMemberUserIds = {
  for (final e in _mockEventData) e.summary.id: e.memberUserIds,
};

List<MockEvent> _buildMockEvents() {
  final Map<String, List<MockAppTransaction>> byEvent = {};
  for (final tx in mockAllTransactions) {
    if (tx.eventId == null || tx.txType != MockTransactionType.expense) continue;
    byEvent.putIfAbsent(tx.eventId!, () => []).add(tx);
  }

  MockEvent build({
    required String eventId,
    required String title,
    required List<String> memberUserIds,
    required bool isSettled,
  }) {
    final txs = byEvent[eventId] ?? [];
    final eventTxs = txs.map(_convertToEventTransaction).toList();
    final lastUpdated = _latestDate(eventTxs);
    final unsettled = _calcUnsettled(eventTxs);
    final summary = EventSummary(
      id: eventId,
      title: title,
      isSettled: isSettled,
      members: memberUserIds.map(displayNameOf).toList(),
      lastUpdatedAt: lastUpdated,
      totalUnsettledAmount: unsettled,
    );
    return MockEvent(
      summary: summary,
      memberUserIds: memberUserIds,
      transactions: eventTxs,
    );
  }

  return [
    build(
      eventId: 'ev_001',
      title: 'はこねゆったり旅',
      memberUserIds: ['u_001', 'u_002', 'u_003', 'u_004'],
      isSettled: false,
    ),
    build(
      eventId: 'ev_002',
      title: '夏フェス はるの陣',
      memberUserIds: ['u_001', 'u_005'],
      isSettled: true,
    ),
    build(
      eventId: 'ev_003',
      title: '秋のキャンプ',
      memberUserIds: ['u_002', 'u_003', 'u_006'],
      isSettled: false,
    ),
    build(
      eventId: 'ev_004',
      title: 'おうちタパス会',
      memberUserIds: ['u_001', 'u_007', 'u_008'],
      isSettled: true,
    ),
    build(
      eventId: 'ev_005',
      title: 'さくらピクニック',
      memberUserIds: ['u_001', 'u_003', 'u_005', 'u_009'],
      isSettled: false,
    ),
    build(
      eventId: 'ev_006',
      title: '沖縄たび',
      memberUserIds: ['u_004', 'u_006', 'u_008', 'u_010'],
      isSettled: false,
    ),
    build(
      eventId: 'ev_007',
      title: 'チーム10人で温泉',
      memberUserIds: [
        'u_001',
        'u_002',
        'u_003',
        'u_004',
        'u_005',
        'u_006',
        'u_007',
        'u_008',
        'u_009',
        'u_010',
      ],
      isSettled: false,
    ),
    build(
      eventId: 'ev_008',
      title: 'ゆきみバスツアー',
      memberUserIds: ['u_002', 'u_005', 'u_007'],
      isSettled: true,
    ),
    build(
      eventId: 'ev_009',
      title: '湖SUP',
      memberUserIds: ['u_001', 'u_004', 'u_009'],
      isSettled: false,
    ),
  ];
}

EventTransaction _convertToEventTransaction(MockAppTransaction tx) {
  final detail = tx.expenseDetail!;
  return EventTransaction(
    id: tx.txId,
    eventId: tx.eventId!,
    title: tx.title,
    paidBy: detail.paidBy,
    totalAmount: tx.totalAmount,
    shares: detail.shares,
    createdAt: tx.date,
  );
}

DateTime _latestDate(List<EventTransaction> txs) {
  if (txs.isEmpty) return DateTime.now();
  txs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return txs.first.createdAt;
}

int _calcUnsettled(List<EventTransaction> txs) {
  if (txs.isEmpty) return 0;
  final Map<String, int> balances = {};
  for (final tx in txs) {
    balances.update(tx.paidBy, (value) => value - tx.totalAmount,
        ifAbsent: () => -tx.totalAmount);
    tx.shares.forEach((userId, amount) {
      balances.update(userId, (value) => value + amount,
          ifAbsent: () => amount);
    });
  }
  int sumPositive = 0;
  for (final value in balances.values) {
    if (value > 0) sumPositive += value;
  }
  return sumPositive;
}
