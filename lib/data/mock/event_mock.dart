import 'package:shakuyousho_app/domain/models/event_models.dart';

final List<EventSummary> mockEvents = [
  EventSummary(
    id: 'ev_001',
    title: '箱根旅行(2024/05)',
    isSettled: false,
    members: ['A さん', 'B さん', 'C さん'],
    lastUpdatedAt: DateTime(2024, 5, 4),
    totalUnsettledAmount: 11700,
  ),
  EventSummary(
    id: 'ev_002',
    title: '夏フェス(2024/08)',
    isSettled: true,
    members: ['A さん', 'みき'],
    lastUpdatedAt: DateTime(2024, 8, 21),
    totalUnsettledAmount: 0,
  ),
];

final List<EventTransaction> mockTransactions = [
  EventTransaction(
    id: 'tx_001',
    eventId: 'ev_001',
    title: '夕食',
    paidBy: 'A さん',
    totalAmount: 6000,
    shares: {'A さん': 2000, 'B さん': 2000, 'C さん': 2000},
    createdAt: DateTime(2024, 5, 3, 19, 30),
  ),
  EventTransaction(
    id: 'tx_002',
    eventId: 'ev_001',
    title: 'カフェ',
    paidBy: 'B さん',
    totalAmount: 1200,
    shares: {'A さん': 400, 'B さん': 400, 'C さん': 400},
    createdAt: DateTime(2024, 5, 3, 22, 10),
  ),
  EventTransaction(
    id: 'tx_003',
    eventId: 'ev_001',
    title: 'おみやげ',
    paidBy: 'C さん',
    totalAmount: 4500,
    shares: {'A さん': 1500, 'B さん': 1500, 'C さん': 1500},
    createdAt: DateTime(2024, 5, 4, 12, 15),
  ),
  EventTransaction(
    id: 'tx_004',
    eventId: 'ev_002',
    title: 'チケット',
    paidBy: 'みき',
    totalAmount: 8000,
    shares: {'A さん': 4000, 'みき': 4000},
    createdAt: DateTime(2024, 8, 20, 18, 0),
  ),
];
