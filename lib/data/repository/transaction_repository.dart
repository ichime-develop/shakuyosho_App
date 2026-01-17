import 'package:shakuyousho_app/domain/models/transaction_model.dart';

abstract class TransactionRepository {
  List<Transaction> getAllTransactions();
  List<Transaction> getTransactionsByEvent(String eventId);
  void upsertTransaction(Transaction tx);
  void deleteTransaction(String txId);
}

/// Mock implementation backed by domain transactions.
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository(List<Transaction> initial)
    : _txs = List<Transaction>.from(initial);

  final List<Transaction> _txs;

  @override
  List<Transaction> getAllTransactions() => List.unmodifiable(_txs);

  @override
  List<Transaction> getTransactionsByEvent(String eventId) =>
      _txs.where((t) => t.eventId == eventId).toList(growable: false);

  @override
  void upsertTransaction(Transaction tx) {
    final idx = _txs.indexWhere((t) => t.id == tx.id);
    if (idx == -1) {
      _txs.add(tx);
    } else {
      _txs[idx] = tx;
    }
  }

  @override
  void deleteTransaction(String txId) {
    final now = DateTime.now();
    final index = _txs.indexWhere((t) => t.id == txId);
    if (index == -1) return;
    final current = _txs[index];
    _txs[index] = current.copyWith(deletedAt: now, updatedAt: now);
  }
}
