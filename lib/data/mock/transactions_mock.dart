import 'package:shakuyousho_app/domain/models/transaction_model.dart'
    as domain_tx;

enum MockTransactionType { expense, repayment }

class ExpenseDetail {
  const ExpenseDetail({
    required this.paidBy,
    required this.shares,
  });

  final String paidBy;
  final Map<String, int> shares;
}

class RepaymentDetail {
  const RepaymentDetail({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  final String fromUserId;
  final String toUserId;
  final int amount;
}

class MockAppTransaction {
  const MockAppTransaction({
    required this.txId,
    required this.txType,
    required this.eventId,
    required this.title,
    required this.date,
    required this.currency,
    required this.totalAmount,
    required this.createdBy,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.expenseDetail,
    this.repaymentDetail,
  });

  final String txId;
  final MockTransactionType txType;
  final String? eventId;
  final String title;
  final DateTime date;
  final String currency;
  final int totalAmount;
  final String createdBy;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final ExpenseDetail? expenseDetail;
  final RepaymentDetail? repaymentDetail;
}

domain_tx.Transaction toDomainTransaction(MockAppTransaction tx) {
  final expense = tx.expenseDetail;
  final repayment = tx.repaymentDetail;
  return domain_tx.Transaction(
    id: tx.txId,
    eventId: tx.eventId,
    type: tx.txType == MockTransactionType.expense
        ? domain_tx.TxType.expense
        : domain_tx.TxType.repayment,
    title: tx.title,
    date: tx.date,
    currency: tx.currency,
    totalAmount: tx.totalAmount,
    participantIds: tx.participantIds,
    paidBy: expense?.paidBy,
    shares: expense?.shares,
    fromUserId: repayment?.fromUserId,
    toUserId: repayment?.toUserId,
    repaymentAmount: repayment?.amount,
    createdBy: tx.createdBy,
    createdAt: tx.createdAt,
    updatedAt: tx.updatedAt,
    deletedAt: tx.deletedAt,
  );
}

final List<domain_tx.Transaction> mockDomainTransactions =
    List<domain_tx.Transaction>.unmodifiable(
  mockAllTransactions.map(toDomainTransaction).toList(growable: false),
);


const _jpy = 'JPY';

List<String> _participantsForExpense(ExpenseDetail d) {
  final ids = <String>{d.paidBy, ...d.shares.keys};
  final list = ids.toList()..sort();
  return List<String>.unmodifiable(list);
}

List<String> _participantsForRepayment(RepaymentDetail d) {
  final ids = <String>{d.fromUserId, d.toUserId};
  final list = ids.toList()..sort();
  return List<String>.unmodifiable(list);
}

bool _sameSet(List<String> a, List<String> b) {
  final sa = a.toSet();
  final sb = b.toSet();
  return sa.length == sb.length && sa.containsAll(sb);
}

/// Debug-only validation for mock data consistency.
///
/// In debug mode, this will assert on:
/// - expense: sum(shares) == totalAmount
/// - repayment: repaymentDetail.amount == totalAmount
/// - participantIds is consistent with details
bool _validateMockAllTransactions(List<MockAppTransaction> txs) {
  for (final tx in txs) {
    if (tx.deletedAt != null) {
      // For PoC we assume deleted items are excluded from UI queries.
      continue;
    }

    assert(tx.currency == _jpy, 'Only JPY is expected in PoC mocks: ${tx.txId}');

    switch (tx.txType) {
      case MockTransactionType.expense:
        final d = tx.expenseDetail;
        assert(d != null, 'expenseDetail must be set for expense: ${tx.txId}');
        if (d == null) break;
        final sum = d.shares.values.fold<int>(0, (p, v) => p + v);
        assert(sum == tx.totalAmount,
            'sum(shares) must equal totalAmount: ${tx.txId} sum=$sum total=${tx.totalAmount}');
        final expected = _participantsForExpense(d);
        assert(_sameSet(tx.participantIds, expected),
            'participantIds must match paidBy+shares.keys: ${tx.txId} expected=$expected actual=${tx.participantIds}');
        break;

      case MockTransactionType.repayment:
        final d = tx.repaymentDetail;
        assert(d != null, 'repaymentDetail must be set for repayment: ${tx.txId}');
        if (d == null) break;
        assert(d.amount == tx.totalAmount,
            'repaymentDetail.amount must equal totalAmount: ${tx.txId} amount=${d.amount} total=${tx.totalAmount}');
        final expected = _participantsForRepayment(d);
        assert(_sameSet(tx.participantIds, expected),
            'participantIds must match from/to: ${tx.txId} expected=$expected actual=${tx.participantIds}');
        break;
    }
  }
  return true;
}

/// Calculates net balances per peer from the perspective of [meUserId].
///
/// Positive value means the peer owes [meUserId]. Negative means [meUserId] owes the peer.
///
/// By default, only personal (eventId == null) transactions are included.
Map<String, int> calcNetByPeer({
  required String meUserId,
  bool includeEvents = false,
  List<MockAppTransaction>? source,
}) {
  final txs = source ?? mockAllTransactions;
  final net = <String, int>{};

  void add(String peer, int delta) {
    if (peer == meUserId) return;
    net[peer] = (net[peer] ?? 0) + delta;
  }

  for (final tx in txs) {
    if (tx.deletedAt != null) continue;
    if (!includeEvents && tx.eventId != null) continue;
    if (!tx.participantIds.contains(meUserId)) continue;

    if (tx.txType == MockTransactionType.expense) {
      final d = tx.expenseDetail;
      if (d == null) continue;

      // Everyone owes their share to the payer.
      for (final entry in d.shares.entries) {
        final userId = entry.key;
        final share = entry.value;
        if (userId == d.paidBy) continue;

        // userId -> payer
        if (meUserId == d.paidBy) {
          // Peer owes me.
          add(userId, share);
        } else if (meUserId == userId) {
          // I owe payer.
          add(d.paidBy, -share);
        }
      }
    } else {
      final d = tx.repaymentDetail;
      if (d == null) continue;

      // from -> to reduces debt.
      if (meUserId == d.toUserId) {
        // Peer paid me.
        add(d.fromUserId, -d.amount);
      } else if (meUserId == d.fromUserId) {
        // I paid peer.
        add(d.toUserId, d.amount);
      }
    }
  }

  return net;
}

final List<MockAppTransaction> mockAllTransactions = [
  // ========== イベント ev_001 ==========
  MockAppTransaction(
    txId: 'tx_ev001_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_001',
    title: 'しんかんせん',
    date: DateTime(2024, 4, 5, 9),
    currency: _jpy,
    totalAmount: 24000,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_002', 'u_003', 'u_004'],
    createdAt: DateTime(2024, 4, 5, 9, 5),
    updatedAt: DateTime(2024, 4, 5, 9, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 6000, 'u_002': 6000, 'u_003': 6000, 'u_004': 6000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev001_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_001',
    title: 'ホテル',
    date: DateTime(2024, 4, 5, 15),
    currency: _jpy,
    totalAmount: 36000,
    createdBy: 'u_003',
    participantIds: const ['u_001', 'u_002', 'u_003', 'u_004'],
    createdAt: DateTime(2024, 4, 5, 15, 5),
    updatedAt: DateTime(2024, 4, 5, 15, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_003',
      shares: {'u_001': 9000, 'u_002': 9000, 'u_003': 9000, 'u_004': 9000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev001_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_001',
    title: 'ランチ',
    date: DateTime(2024, 4, 6, 11),
    currency: _jpy,
    totalAmount: 6400,
    createdBy: 'u_002',
    participantIds: const ['u_001', 'u_002', 'u_003', 'u_004'],
    createdAt: DateTime(2024, 4, 6, 11, 2),
    updatedAt: DateTime(2024, 4, 6, 11, 2),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_002',
      shares: {'u_001': 1600, 'u_002': 1600, 'u_003': 1600, 'u_004': 1600},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev001_004',
    txType: MockTransactionType.expense,
    eventId: 'ev_001',
    title: 'おみやげ',
    date: DateTime(2024, 4, 6, 15),
    currency: _jpy,
    totalAmount: 5200,
    createdBy: 'u_004',
    participantIds: const ['u_001', 'u_002', 'u_003', 'u_004'],
    createdAt: DateTime(2024, 4, 6, 15, 10),
    updatedAt: DateTime(2024, 4, 6, 15, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_004',
      shares: {'u_001': 1300, 'u_002': 1300, 'u_003': 1300, 'u_004': 1300},
    ),
  ),
  // ========== イベント ev_002 ==========
  MockAppTransaction(
    txId: 'tx_ev002_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_002',
    title: 'チケット',
    date: DateTime(2024, 8, 18, 11),
    currency: _jpy,
    totalAmount: 8000,
    createdBy: 'u_005',
    participantIds: const ['u_001', 'u_005'],
    createdAt: DateTime(2024, 8, 18, 11, 10),
    updatedAt: DateTime(2024, 8, 18, 11, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {'u_001': 4000, 'u_005': 4000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev002_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_002',
    title: 'のみもの',
    date: DateTime(2024, 8, 19, 19),
    currency: _jpy,
    totalAmount: 3600,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_005'],
    createdAt: DateTime(2024, 8, 19, 19, 4),
    updatedAt: DateTime(2024, 8, 19, 19, 4),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1800, 'u_005': 1800},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev002_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_002',
    title: 'ホテル',
    date: DateTime(2024, 8, 20, 22),
    currency: _jpy,
    totalAmount: 12000,
    createdBy: 'u_005',
    participantIds: const ['u_001', 'u_005'],
    createdAt: DateTime(2024, 8, 20, 22, 8),
    updatedAt: DateTime(2024, 8, 20, 22, 8),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {'u_001': 6000, 'u_005': 6000},
    ),
  ),
  // ========== イベント ev_003 ==========
  MockAppTransaction(
    txId: 'tx_ev003_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_003',
    title: 'テントサイト',
    date: DateTime(2024, 10, 3, 8),
    currency: _jpy,
    totalAmount: 9000,
    createdBy: 'u_002',
    participantIds: const ['u_002', 'u_003', 'u_006'],
    createdAt: DateTime(2024, 10, 3, 8, 5),
    updatedAt: DateTime(2024, 10, 3, 8, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_002',
      shares: {'u_002': 3000, 'u_003': 3000, 'u_006': 3000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev003_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_003',
    title: 'BBQざいりょう',
    date: DateTime(2024, 10, 3, 16),
    currency: _jpy,
    totalAmount: 6000,
    createdBy: 'u_003',
    participantIds: const ['u_002', 'u_003', 'u_006'],
    createdAt: DateTime(2024, 10, 3, 16, 3),
    updatedAt: DateTime(2024, 10, 3, 16, 3),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_003',
      shares: {'u_002': 2000, 'u_003': 2000, 'u_006': 2000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev003_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_003',
    title: '薪',
    date: DateTime(2024, 10, 4, 9),
    currency: _jpy,
    totalAmount: 1500,
    createdBy: 'u_006',
    participantIds: const ['u_002', 'u_003', 'u_006'],
    createdAt: DateTime(2024, 10, 4, 9, 2),
    updatedAt: DateTime(2024, 10, 4, 9, 2),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_006',
      shares: {'u_002': 500, 'u_003': 500, 'u_006': 500},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev003_004',
    txType: MockTransactionType.expense,
    eventId: 'ev_003',
    title: 'レンタカー',
    date: DateTime(2024, 10, 4, 11),
    currency: _jpy,
    totalAmount: 7200,
    createdBy: 'u_002',
    participantIds: const ['u_002', 'u_003', 'u_006'],
    createdAt: DateTime(2024, 10, 4, 11, 5),
    updatedAt: DateTime(2024, 10, 4, 11, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_002',
      shares: {'u_002': 2400, 'u_003': 2400, 'u_006': 2400},
    ),
  ),
  // ========== イベント ev_004 ==========
  MockAppTransaction(
    txId: 'tx_ev004_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_004',
    title: 'たべもの',
    date: DateTime(2025, 2, 8, 9),
    currency: _jpy,
    totalAmount: 5400,
    createdBy: 'u_007',
    participantIds: const ['u_001', 'u_007', 'u_008'],
    createdAt: DateTime(2025, 2, 8, 9, 4),
    updatedAt: DateTime(2025, 2, 8, 9, 4),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_007',
      shares: {'u_001': 1800, 'u_007': 1800, 'u_008': 1800},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev004_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_004',
    title: 'のみもの',
    date: DateTime(2025, 2, 8, 18),
    currency: _jpy,
    totalAmount: 3000,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_007', 'u_008'],
    createdAt: DateTime(2025, 2, 8, 18, 3),
    updatedAt: DateTime(2025, 2, 8, 18, 3),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1000, 'u_007': 1000, 'u_008': 1000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev004_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_004',
    title: 'デザート',
    date: DateTime(2025, 2, 8, 20),
    currency: _jpy,
    totalAmount: 2700,
    createdBy: 'u_008',
    participantIds: const ['u_001', 'u_007', 'u_008'],
    createdAt: DateTime(2025, 2, 8, 20, 5),
    updatedAt: DateTime(2025, 2, 8, 20, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_008',
      shares: {'u_001': 900, 'u_007': 900, 'u_008': 900},
    ),
  ),
  // ========== イベント ev_005 ==========
  MockAppTransaction(
    txId: 'tx_ev005_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_005',
    title: 'ピクニックシート',
    date: DateTime(2025, 3, 28, 9),
    currency: _jpy,
    totalAmount: 4000,
    createdBy: 'u_009',
    participantIds: const ['u_001', 'u_003', 'u_005', 'u_009'],
    createdAt: DateTime(2025, 3, 28, 9, 10),
    updatedAt: DateTime(2025, 3, 28, 9, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_009',
      shares: {'u_001': 1000, 'u_003': 1000, 'u_005': 1000, 'u_009': 1000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev005_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_005',
    title: 'おべんとう',
    date: DateTime(2025, 3, 28, 12),
    currency: _jpy,
    totalAmount: 5200,
    createdBy: 'u_003',
    participantIds: const ['u_001', 'u_003', 'u_005', 'u_009'],
    createdAt: DateTime(2025, 3, 28, 12, 10),
    updatedAt: DateTime(2025, 3, 28, 12, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_003',
      shares: {'u_001': 1300, 'u_003': 1300, 'u_005': 1300, 'u_009': 1300},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev005_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_005',
    title: 'おやつ',
    date: DateTime(2025, 3, 28, 15),
    currency: _jpy,
    totalAmount: 2800,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_003', 'u_005', 'u_009'],
    createdAt: DateTime(2025, 3, 28, 15, 5),
    updatedAt: DateTime(2025, 3, 28, 15, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 700, 'u_003': 700, 'u_005': 700, 'u_009': 700},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev005_004',
    txType: MockTransactionType.expense,
    eventId: 'ev_005',
    title: 'でんしゃ',
    date: DateTime(2025, 3, 28, 18),
    currency: _jpy,
    totalAmount: 6400,
    createdBy: 'u_005',
    participantIds: const ['u_001', 'u_003', 'u_005', 'u_009'],
    createdAt: DateTime(2025, 3, 28, 18, 6),
    updatedAt: DateTime(2025, 3, 28, 18, 6),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {'u_001': 1600, 'u_003': 1600, 'u_005': 1600, 'u_009': 1600},
    ),
  ),
  // ========== イベント ev_006 ==========
  MockAppTransaction(
    txId: 'tx_ev006_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_006',
    title: 'ひこうき',
    date: DateTime(2025, 7, 2, 7),
    currency: _jpy,
    totalAmount: 64000,
    createdBy: 'u_004',
    participantIds: const ['u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2025, 7, 2, 7, 10),
    updatedAt: DateTime(2025, 7, 2, 7, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_004',
      shares: {'u_004': 16000, 'u_006': 16000, 'u_008': 16000, 'u_010': 16000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev006_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_006',
    title: 'ホテル',
    date: DateTime(2025, 7, 2, 20),
    currency: _jpy,
    totalAmount: 48000,
    createdBy: 'u_006',
    participantIds: const ['u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2025, 7, 2, 20, 8),
    updatedAt: DateTime(2025, 7, 2, 20, 8),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_006',
      shares: {'u_004': 12000, 'u_006': 12000, 'u_008': 12000, 'u_010': 12000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev006_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_006',
    title: 'レンタカー',
    date: DateTime(2025, 7, 3, 9),
    currency: _jpy,
    totalAmount: 12000,
    createdBy: 'u_008',
    participantIds: const ['u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2025, 7, 3, 9, 5),
    updatedAt: DateTime(2025, 7, 3, 9, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_008',
      shares: {'u_004': 3000, 'u_006': 3000, 'u_008': 3000, 'u_010': 3000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev006_004',
    txType: MockTransactionType.expense,
    eventId: 'ev_006',
    title: 'ディナー',
    date: DateTime(2025, 7, 3, 19),
    currency: _jpy,
    totalAmount: 20000,
    createdBy: 'u_010',
    participantIds: const ['u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2025, 7, 3, 19, 8),
    updatedAt: DateTime(2025, 7, 3, 19, 8),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_010',
      shares: {'u_004': 5000, 'u_006': 5000, 'u_008': 5000, 'u_010': 5000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev006_005',
    txType: MockTransactionType.expense,
    eventId: 'ev_006',
    title: 'マリンアクティビティ',
    date: DateTime(2025, 7, 4, 10),
    currency: _jpy,
    totalAmount: 16000,
    createdBy: 'u_004',
    participantIds: const ['u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2025, 7, 4, 10, 5),
    updatedAt: DateTime(2025, 7, 4, 10, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_004',
      shares: {'u_004': 4000, 'u_006': 4000, 'u_008': 4000, 'u_010': 4000},
    ),
  ),
  // ========== イベント ev_007 ==========
  MockAppTransaction(
    txId: 'tx_ev007_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_007',
    title: 'バスチャーター',
    date: DateTime(2025, 5, 10, 7),
    currency: _jpy,
    totalAmount: 50000,
    createdBy: 'u_002',
    participantIds: const [
      'u_001',
      'u_002',
      'u_003',
      'u_004',
      'u_005',
      'u_006',
      'u_007',
      'u_008',
      'u_009',
      'u_010'
    ],
    createdAt: DateTime(2025, 5, 10, 7, 10),
    updatedAt: DateTime(2025, 5, 10, 7, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_002',
      shares: {
        'u_001': 5000,
        'u_002': 5000,
        'u_003': 5000,
        'u_004': 5000,
        'u_005': 5000,
        'u_006': 5000,
        'u_007': 5000,
        'u_008': 5000,
        'u_009': 5000,
        'u_010': 5000,
      },
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev007_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_007',
    title: 'ロッジ',
    date: DateTime(2025, 5, 10, 18),
    currency: _jpy,
    totalAmount: 80000,
    createdBy: 'u_005',
    participantIds: const [
      'u_001',
      'u_002',
      'u_003',
      'u_004',
      'u_005',
      'u_006',
      'u_007',
      'u_008',
      'u_009',
      'u_010'
    ],
    createdAt: DateTime(2025, 5, 10, 18, 6),
    updatedAt: DateTime(2025, 5, 10, 18, 6),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {
        'u_001': 8000,
        'u_002': 8000,
        'u_003': 8000,
        'u_004': 8000,
        'u_005': 8000,
        'u_006': 8000,
        'u_007': 8000,
        'u_008': 8000,
        'u_009': 8000,
        'u_010': 8000,
      },
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev007_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_007',
    title: 'ばんごはん',
    date: DateTime(2025, 5, 10, 20),
    currency: _jpy,
    totalAmount: 30000,
    createdBy: 'u_007',
    participantIds: const [
      'u_001',
      'u_002',
      'u_003',
      'u_004',
      'u_005',
      'u_006',
      'u_007',
      'u_008',
      'u_009',
      'u_010'
    ],
    createdAt: DateTime(2025, 5, 10, 20, 6),
    updatedAt: DateTime(2025, 5, 10, 20, 6),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_007',
      shares: {
        'u_001': 3000,
        'u_002': 3000,
        'u_003': 3000,
        'u_004': 3000,
        'u_005': 3000,
        'u_006': 3000,
        'u_007': 3000,
        'u_008': 3000,
        'u_009': 3000,
        'u_010': 3000,
      },
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev007_004',
    txType: MockTransactionType.expense,
    eventId: 'ev_007',
    title: 'おんせんパス',
    date: DateTime(2025, 5, 11, 9),
    currency: _jpy,
    totalAmount: 20000,
    createdBy: 'u_003',
    participantIds: const [
      'u_001',
      'u_002',
      'u_003',
      'u_004',
      'u_005',
      'u_006',
      'u_007',
      'u_008',
      'u_009',
      'u_010'
    ],
    createdAt: DateTime(2025, 5, 11, 9, 4),
    updatedAt: DateTime(2025, 5, 11, 9, 4),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_003',
      shares: {
        'u_001': 2000,
        'u_002': 2000,
        'u_003': 2000,
        'u_004': 2000,
        'u_005': 2000,
        'u_006': 2000,
        'u_007': 2000,
        'u_008': 2000,
        'u_009': 2000,
        'u_010': 2000,
      },
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev007_005',
    txType: MockTransactionType.expense,
    eventId: 'ev_007',
    title: 'あさごはん',
    date: DateTime(2025, 5, 11, 8),
    currency: _jpy,
    totalAmount: 15000,
    createdBy: 'u_009',
    participantIds: const [
      'u_001',
      'u_002',
      'u_003',
      'u_004',
      'u_005',
      'u_006',
      'u_007',
      'u_008',
      'u_009',
      'u_010'
    ],
    createdAt: DateTime(2025, 5, 11, 8, 10),
    updatedAt: DateTime(2025, 5, 11, 8, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_009',
      shares: {
        'u_001': 1500,
        'u_002': 1500,
        'u_003': 1500,
        'u_004': 1500,
        'u_005': 1500,
        'u_006': 1500,
        'u_007': 1500,
        'u_008': 1500,
        'u_009': 1500,
        'u_010': 1500,
      },
    ),
  ),
  // ========== イベント ev_008 ==========
  MockAppTransaction(
    txId: 'tx_ev008_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_008',
    title: 'バス',
    date: DateTime(2024, 12, 12, 7, 30),
    currency: _jpy,
    totalAmount: 9000,
    createdBy: 'u_002',
    participantIds: const ['u_002', 'u_005', 'u_007'],
    createdAt: DateTime(2024, 12, 12, 7, 35),
    updatedAt: DateTime(2024, 12, 12, 7, 35),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_002',
      shares: {'u_002': 3000, 'u_005': 3000, 'u_007': 3000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev008_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_008',
    title: 'ランチ',
    date: DateTime(2024, 12, 12, 13),
    currency: _jpy,
    totalAmount: 4500,
    createdBy: 'u_005',
    participantIds: const ['u_002', 'u_005', 'u_007'],
    createdAt: DateTime(2024, 12, 12, 13, 6),
    updatedAt: DateTime(2024, 12, 12, 13, 6),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {'u_002': 1500, 'u_005': 1500, 'u_007': 1500},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev008_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_008',
    title: 'おみやげ',
    date: DateTime(2024, 12, 12, 17),
    currency: _jpy,
    totalAmount: 3600,
    createdBy: 'u_007',
    participantIds: const ['u_002', 'u_005', 'u_007'],
    createdAt: DateTime(2024, 12, 12, 17, 5),
    updatedAt: DateTime(2024, 12, 12, 17, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_007',
      shares: {'u_002': 1200, 'u_005': 1200, 'u_007': 1200},
    ),
  ),
  // ========== イベント ev_009 ==========
  MockAppTransaction(
    txId: 'tx_ev009_001',
    txType: MockTransactionType.expense,
    eventId: 'ev_009',
    title: 'SUPレンタル',
    date: DateTime(2025, 7, 9, 9),
    currency: _jpy,
    totalAmount: 7500,
    createdBy: 'u_004',
    participantIds: const ['u_001', 'u_004', 'u_009'],
    createdAt: DateTime(2025, 7, 9, 9, 5),
    updatedAt: DateTime(2025, 7, 9, 9, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_004',
      shares: {'u_001': 2500, 'u_004': 2500, 'u_009': 2500},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev009_002',
    txType: MockTransactionType.expense,
    eventId: 'ev_009',
    title: 'ガソリン',
    date: DateTime(2025, 7, 9, 12),
    currency: _jpy,
    totalAmount: 4200,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_004', 'u_009'],
    createdAt: DateTime(2025, 7, 9, 12, 4),
    updatedAt: DateTime(2025, 7, 9, 12, 4),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1400, 'u_004': 1400, 'u_009': 1400},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_ev009_003',
    txType: MockTransactionType.expense,
    eventId: 'ev_009',
    title: 'カフェ',
    date: DateTime(2025, 7, 9, 15),
    currency: _jpy,
    totalAmount: 3600,
    createdBy: 'u_009',
    participantIds: const ['u_001', 'u_004', 'u_009'],
    createdAt: DateTime(2025, 7, 9, 15, 5),
    updatedAt: DateTime(2025, 7, 9, 15, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_009',
      shares: {'u_001': 1200, 'u_004': 1200, 'u_009': 1200},
    ),
  ),
  // ========== 個人 expense ==========
  MockAppTransaction(
    txId: 'tx_p001',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ランチ（ゆうき）',
    date: DateTime(2025, 1, 6, 12, 30),
    currency: _jpy,
    totalAmount: 2400,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_002'],
    createdAt: DateTime(2025, 1, 6, 12, 35),
    updatedAt: DateTime(2025, 1, 6, 12, 35),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1200, 'u_002': 1200},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p002',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'カフェ（まな）',
    date: DateTime(2025, 1, 12, 16),
    currency: _jpy,
    totalAmount: 1600,
    createdBy: 'u_003',
    participantIds: const ['u_001', 'u_003'],
    createdAt: DateTime(2025, 1, 12, 16, 5),
    updatedAt: DateTime(2025, 1, 12, 16, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_003',
      shares: {'u_001': 800, 'u_003': 800},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p003',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'えいが（けんた）',
    date: DateTime(2025, 1, 18, 20),
    currency: _jpy,
    totalAmount: 3600,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_004'],
    createdAt: DateTime(2025, 1, 18, 20, 5),
    updatedAt: DateTime(2025, 1, 18, 20, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1800, 'u_004': 1800},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p004',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ギフト（みさき）',
    date: DateTime(2025, 1, 25, 10),
    currency: _jpy,
    totalAmount: 3000,
    createdBy: 'u_005',
    participantIds: const ['u_001', 'u_005'],
    createdAt: DateTime(2025, 1, 25, 10, 5),
    updatedAt: DateTime(2025, 1, 25, 10, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_005',
      shares: {'u_001': 1500, 'u_005': 1500},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p005',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'タクシー（あやこ）',
    date: DateTime(2025, 1, 28, 22),
    currency: _jpy,
    totalAmount: 1800,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_006'],
    createdAt: DateTime(2025, 1, 28, 22, 5),
    updatedAt: DateTime(2025, 1, 28, 22, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 900, 'u_006': 900},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p006',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ディナー（なおき）',
    date: DateTime(2025, 2, 2, 19),
    currency: _jpy,
    totalAmount: 5200,
    createdBy: 'u_007',
    participantIds: const ['u_001', 'u_007'],
    createdAt: DateTime(2025, 2, 2, 19, 6),
    updatedAt: DateTime(2025, 2, 2, 19, 6),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_007',
      shares: {'u_001': 2600, 'u_007': 2600},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p007',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ランチ（さとる）',
    date: DateTime(2025, 2, 5, 12),
    currency: _jpy,
    totalAmount: 2800,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_008'],
    createdAt: DateTime(2025, 2, 5, 12, 4),
    updatedAt: DateTime(2025, 2, 5, 12, 4),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1400, 'u_008': 1400},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p008',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'カフェ（りえ）',
    date: DateTime(2025, 2, 9, 15),
    currency: _jpy,
    totalAmount: 2000,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_009'],
    createdAt: DateTime(2025, 2, 9, 15, 5),
    updatedAt: DateTime(2025, 2, 9, 15, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1000, 'u_009': 1000},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p009',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ぶんぐ（ゆうき＆まな）',
    date: DateTime(2025, 2, 15, 11),
    currency: _jpy,
    totalAmount: 3600,
    createdBy: 'u_001',
    participantIds: const ['u_001', 'u_002', 'u_003'],
    createdAt: DateTime(2025, 2, 15, 11, 5),
    updatedAt: DateTime(2025, 2, 15, 11, 5),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_001',
      shares: {'u_001': 1200, 'u_002': 1200, 'u_003': 1200},
    ),
  ),
  MockAppTransaction(
    txId: 'tx_p010',
    txType: MockTransactionType.expense,
    eventId: null,
    title: 'ライブ',
    date: DateTime(2025, 2, 20, 18),
    currency: _jpy,
    totalAmount: 6000,
    createdBy: 'u_006',
    participantIds: const ['u_001', 'u_005', 'u_006'],
    createdAt: DateTime(2025, 2, 20, 18, 10),
    updatedAt: DateTime(2025, 2, 20, 18, 10),
    expenseDetail: const ExpenseDetail(
      paidBy: 'u_006',
      shares: {'u_001': 2000, 'u_005': 2000, 'u_006': 2000},
    ),
  ),
  // ========== 個人 repayment ==========
  MockAppTransaction(
    txId: 'tx_r001',
    txType: MockTransactionType.repayment,
    eventId: null,
    title: 'ゆうき→いちか へんさい',
    date: DateTime(2025, 2, 3, 10),
    currency: _jpy,
    totalAmount: 2000,
    createdBy: 'u_002',
    participantIds: const ['u_001', 'u_002'],
    createdAt: DateTime(2025, 2, 3, 10, 2),
    updatedAt: DateTime(2025, 2, 3, 10, 2),
    repaymentDetail: const RepaymentDetail(
      fromUserId: 'u_002',
      toUserId: 'u_001',
      amount: 2000,
    ),
  ),
  MockAppTransaction(
    txId: 'tx_r002',
    txType: MockTransactionType.repayment,
    eventId: null,
    title: 'まな→いちか へんさい',
    date: DateTime(2025, 2, 12, 9),
    currency: _jpy,
    totalAmount: 1500,
    createdBy: 'u_003',
    participantIds: const ['u_001', 'u_003'],
    createdAt: DateTime(2025, 2, 12, 9, 3),
    updatedAt: DateTime(2025, 2, 12, 9, 3),
    repaymentDetail: const RepaymentDetail(
      fromUserId: 'u_003',
      toUserId: 'u_001',
      amount: 1500,
    ),
  ),
  MockAppTransaction(
    txId: 'tx_r003',
    txType: MockTransactionType.repayment,
    eventId: null,
    title: 'みさき→いちか へんさい',
    date: DateTime(2025, 2, 18, 13),
    currency: _jpy,
    totalAmount: 2500,
    createdBy: 'u_005',
    participantIds: const ['u_001', 'u_005'],
    createdAt: DateTime(2025, 2, 18, 13, 4),
    updatedAt: DateTime(2025, 2, 18, 13, 4),
    repaymentDetail: const RepaymentDetail(
      fromUserId: 'u_005',
      toUserId: 'u_001',
      amount: 2500,
    ),
  ),
  MockAppTransaction(
    txId: 'tx_r004',
    txType: MockTransactionType.repayment,
    eventId: null,
    title: 'けんた→いちか へんさい',
    date: DateTime(2025, 2, 21, 18),
    currency: _jpy,
    totalAmount: 1800,
    createdBy: 'u_004',
    participantIds: const ['u_001', 'u_004'],
    createdAt: DateTime(2025, 2, 21, 18, 5),
    updatedAt: DateTime(2025, 2, 21, 18, 5),
    repaymentDetail: const RepaymentDetail(
      fromUserId: 'u_004',
      toUserId: 'u_001',
      amount: 1800,
    ),
  ),
];

// Validates mock invariants in debug builds (asserts are stripped in release).
// Ignore the returned value.
final bool _mockValidationOk = _validateMockAllTransactions(mockAllTransactions);


// 参考: u_001 視点の純残高（自動算出）
//
// 手動で数値を書くとデータ追加/修正でズレやすいため、下記関数で都度算出してください。
// - 個人（eventId == null）のみ: calcNetByPeer(meUserId: 'u_001')
// - イベント含む全取引: calcNetByPeer(meUserId: 'u_001', includeEvents: true)
//
// 正の値: 相手が u_001 に返すべき（相手→u_001 の負債）
// 負の値: u_001 が相手に返すべき（u_001→相手 の負債）
