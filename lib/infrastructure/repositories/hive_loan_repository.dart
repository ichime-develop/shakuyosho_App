import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/domain/repositories/loan_repository.dart';

/// Hive-backed implementation for Loan persistence (Map storage).
class HiveLoanRepository implements LoanRepository {
  HiveLoanRepository({required Box<Map> loanBox}) : _loanBox = loanBox;

  final Box<Map> _loanBox;

  @override
  Future<List<Loan>> getAll() async {
    final loans =
        _loanBox.values
            .map((raw) => Loan.fromMap(_castMap(raw)))
            .where((l) => l.deletedAt == null)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return loans;
  }

  @override
  Future<Loan?> getById(String id) async {
    final raw = _loanBox.get(id);
    if (raw == null) return null;
    final loan = Loan.fromMap(_castMap(raw), id: id);
    return loan.deletedAt == null ? loan : null;
  }

  @override
  Future<List<Loan>> getByCounterparty(String counterpartyId) async {
    final loans =
        _loanBox.values
            .map((raw) => Loan.fromMap(_castMap(raw)))
            .where(
              (l) => l.counterpartyId == counterpartyId && l.deletedAt == null,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return loans;
  }

  @override
  Future<void> upsert(Loan loan) async {
    _loanBox.put(loan.id, loan.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final raw = _loanBox.get(id);
    if (raw == null) return;
    final current = Loan.fromMap(_castMap(raw), id: id);
    if (current.deletedAt != null) return;
    _loanBox.put(id, current.copyWith(deletedAt: DateTime.now()).toMap());
  }

  @override
  Future<({int lentTotal, int borrowedTotal})> calcTotals() async {
    var lent = 0;
    var borrowed = 0;
    for (final raw in _loanBox.values) {
      final loan = Loan.fromMap(_castMap(raw));
      if (loan.deletedAt != null) continue;
      // 承認済み（approved）のLoanのみ集計
      if (loan.status != LoanStatus.approved) continue;
      if (loan.direction == LoanDirection.lent) {
        lent += loan.remainingYen;
      } else {
        borrowed += loan.remainingYen;
      }
    }
    return (lentTotal: lent, borrowedTotal: borrowed);
  }

  @override
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
