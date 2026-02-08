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
      if (l.isRepaid) continue;
      if (l.lenderUserId == currentUserId) {
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
    Loan(
      id: 'loan_001',
      lenderUserId: currentUserId,
      borrowerUserId: 'u_002',
      counterpartyId: 'u_002',
      amountYen: 10000,
      purpose: 'おこのみやき の だい',
      dueDate: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 1, 15),
      iouNo: 'IOU-8G5X-3Q2M',
      repayments: const [],
    ),
    Loan(
      id: 'loan_002',
      lenderUserId: 'u_003',
      borrowerUserId: currentUserId,
      counterpartyId: 'u_003',
      amountYen: 5000,
      purpose: 'でんしゃちん',
      dueDate: DateTime(2026, 2, 15),
      createdAt: DateTime(2026, 1, 20),
      iouNo: 'IOU-9H2K-7L1N',
      repayments: const [],
    ),
    Loan(
      id: 'loan_003',
      lenderUserId: currentUserId,
      borrowerUserId: 'u_002',
      counterpartyId: 'u_002',
      amountYen: 3000,
      purpose: 'らんち だい',
      dueDate: DateTime(2026, 2, 28),
      createdAt: DateTime(2026, 1, 25),
      iouNo: 'IOU-4K7P-2R9S',
      repayments: [Repayment(amountYen: 1000, paidAt: DateTime(2026, 1, 30))],
    ),
    Loan(
      id: 'loan_004',
      lenderUserId: 'u_004',
      borrowerUserId: currentUserId,
      counterpartyId: 'u_004',
      amountYen: 2000,
      purpose: 'コンビニ',
      dueDate: DateTime(2026, 2, 10),
      createdAt: DateTime(2026, 2, 1),
      iouNo: 'IOU-5M3N-8T4V',
      repayments: const [],
    ),
  ];
}
