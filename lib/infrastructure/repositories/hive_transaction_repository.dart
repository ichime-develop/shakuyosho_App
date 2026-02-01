import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';

/// Hive-backed implementation for Transaction persistence.
class HiveTransactionRepository implements TransactionRepository {
  HiveTransactionRepository({required Box<Transaction> transactionBox})
    : _transactionBox = transactionBox;

  final Box<Transaction> _transactionBox;

  @override
  List<Transaction> getByEventId(String eventId) {
    return _transactionBox.values
        .where((t) => t.eventId == eventId && t.deletedAt == null)
        .toList(growable: false);
  }

  @override
  void upsert(Transaction tx) {
    _transactionBox.put(tx.id, tx);
  }

  @override
  void delete(String txId) {
    final current = _transactionBox.get(txId);
    if (current == null) return;
    final now = DateTime.now();
    _transactionBox.put(txId, current.copyWith(deletedAt: now, updatedAt: now));
  }
}
