import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';

/// Loan seed data aligned with mock users/threads.
final List<Loan> mockLoans = List<Loan>.unmodifiable([
  // u_002 に かした（自分→u_002）
  Loan(
    id: 'loan_001',
    direction: LoanDirection.lent,
    counterpartyId: 'u_002',
    createdBy: currentUserId,
    legacyCounterpartyName: displayNameOf('u_002'),
    amountYen: 10000,
    purpose: 'おこのみやき の だい',
    dueDate: DateTime(2026, 3, 1),
    status: LoanStatus.approved,
    createdAt: DateTime(2026, 1, 15),
    iouNo: 'IOU-8G5X-3Q2M',
    repayments: const [],
  ),
  // u_003 から かりた（u_003→自分）
  Loan(
    id: 'loan_002',
    direction: LoanDirection.borrowed,
    counterpartyId: 'u_003',
    createdBy: 'u_003',
    legacyCounterpartyName: displayNameOf('u_003'),
    amountYen: 5000,
    purpose: 'でんしゃちん',
    dueDate: DateTime(2026, 2, 15),
    status: LoanStatus.approved,
    createdAt: DateTime(2026, 1, 20),
    iouNo: 'IOU-9H2K-7L1N',
    repayments: const [],
  ),
  // u_002 に かした（2件目・部分返済あり）
  Loan(
    id: 'loan_003',
    direction: LoanDirection.lent,
    counterpartyId: 'u_002',
    createdBy: currentUserId,
    legacyCounterpartyName: displayNameOf('u_002'),
    amountYen: 3000,
    purpose: 'らんち だい',
    dueDate: DateTime(2026, 2, 28),
    status: LoanStatus.approved,
    createdAt: DateTime(2026, 1, 25),
    iouNo: 'IOU-4K7P-2R9S',
    repayments: [Repayment(amountYen: 1000, paidAt: DateTime(2026, 1, 30))],
  ),
  // u_004 から かりた（pending状態）
  Loan(
    id: 'loan_004',
    direction: LoanDirection.borrowed,
    counterpartyId: 'u_004',
    createdBy: 'u_004',
    legacyCounterpartyName: displayNameOf('u_004'),
    amountYen: 2000,
    purpose: 'コンビニ',
    dueDate: DateTime(2026, 2, 10),
    status: LoanStatus.pending,
    createdAt: DateTime(2026, 2, 1),
    iouNo: 'IOU-5M3N-8T4V',
    repayments: const [],
  ),
]);
