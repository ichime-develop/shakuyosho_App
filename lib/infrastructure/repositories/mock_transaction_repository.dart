import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';

/// Mock implementation backed by domain transactions.
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository(List<Transaction> initial)
    : _txs = List<Transaction>.from(initial);

  final List<Transaction> _txs;

  @override
  List<Transaction> getByEventId(String eventId) => _txs
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList(growable: false);

  @override
  void upsert(Transaction tx) {
    final idx = _txs.indexWhere((t) => t.id == tx.id);
    if (idx == -1) {
      _txs.add(tx);
    } else {
      _txs[idx] = tx;
    }
  }

  @override
  void delete(String txId) {
    final now = DateTime.now();
    final index = _txs.indexWhere((t) => t.id == txId);
    if (index == -1) return;
    final current = _txs[index];
    _txs[index] = current.copyWith(deletedAt: now, updatedAt: now);
  }
}
