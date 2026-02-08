import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';

/// Loan seed data aligned with mock users/threads.
final List<Loan> mockLoans = List<Loan>.unmodifiable([
  // 自分が u_002 にかした
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
  // u_003 が自分にかした
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
  // 自分が u_002 にかした（2件目・部分返済あり）
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
  // u_004 が自分にかした
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
]);
