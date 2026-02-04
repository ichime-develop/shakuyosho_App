import 'package:shakuyousho_app/data/mock/users_mock.dart';

import '../../domain/models/loan_model.dart';
import '../../domain/repositories/loan_repository.dart';

/// LoanRepositoryのMock実装
class MockLoanRepository implements LoanRepository {
  MockLoanRepository({List<Loan>? initialLoans})
    : _loans = {for (final l in initialLoans ?? _defaultLoans) l.id: l};

  final Map<String, Loan> _loans;

  @override
  Future<List<Loan>> getAll() async {
    return _loans.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<Loan?> getById(String id) async {
    return _loans[id];
  }

  @override
  Future<List<Loan>> getByCounterparty(String counterpartyId) async {
    return _loans.values
        .where((l) => l.counterpartyId == counterpartyId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> upsert(Loan loan) async {
    _loans[loan.id] = loan;
  }

  @override
  Future<void> delete(String id) async {
    _loans.remove(id);
  }

  @override
  Future<({int lentTotal, int borrowedTotal})> calcTotals() async {
    var lent = 0;
    var borrowed = 0;

    for (final l in _loans.values) {
      if (l.direction == LoanDirection.lent) {
        lent += l.remainingYen;
      } else {
        borrowed += l.remainingYen;
      }
    }

    return (lentTotal: lent, borrowedTotal: borrowed);
  }

  @override
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ────────────────────────────────────────────────────────────────
  // デフォルトモックデータ
  // ────────────────────────────────────────────────────────────────
  static final _defaultLoans = <Loan>[
    // Bさんに かした（自分→Bさん）
    Loan(
      id: 'loan_001',
      direction: LoanDirection.lent,
      counterpartyId: 'u_002',
      createdBy: currentUserId,
      amountYen: 10000,
      purpose: 'おこのみやき の だい',
      dueDate: DateTime(2026, 3, 1),
      status: LoanStatus.approved,
      createdAt: DateTime(2026, 1, 15),
      iouNo: 'IOU-8G5X-3Q2M',
      repayments: const [],
    ),
    // Cさんから かりた（Cさん→自分）
    Loan(
      id: 'loan_002',
      direction: LoanDirection.borrowed,
      counterpartyId: 'u_003',
      createdBy: 'u_003',
      amountYen: 5000,
      purpose: 'でんしゃちん',
      dueDate: DateTime(2026, 2, 15),
      status: LoanStatus.approved,
      createdAt: DateTime(2026, 1, 20),
      iouNo: 'IOU-9H2K-7L1N',
      repayments: const [],
    ),
    // Bさんに かした（2件目・部分返済あり）
    Loan(
      id: 'loan_003',
      direction: LoanDirection.lent,
      counterpartyId: 'u_002',
      createdBy: currentUserId,
      amountYen: 3000,
      purpose: 'らんち だい',
      dueDate: DateTime(2026, 2, 28),
      status: LoanStatus.approved,
      createdAt: DateTime(2026, 1, 25),
      iouNo: 'IOU-4K7P-2R9S',
      repayments: [Repayment(amountYen: 1000, paidAt: DateTime(2026, 1, 30))],
    ),
    // Dさんから かりた（pending状態）
    Loan(
      id: 'loan_004',
      direction: LoanDirection.borrowed,
      counterpartyId: 'u_004',
      createdBy: 'u_004',
      amountYen: 2000,
      purpose: 'コンビニ',
      dueDate: DateTime(2026, 2, 10),
      status: LoanStatus.pending,
      createdAt: DateTime(2026, 2, 1),
      iouNo: 'IOU-5M3N-8T4V',
      repayments: const [],
    ),
  ];
}
