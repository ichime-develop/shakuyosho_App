import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';

/// Hive-backed implementation for Transaction persistence.
class HiveTransactionRepository implements TransactionRepository {
  HiveTransactionRepository({required Box<Map> transactionBox})
    : _transactionBox = transactionBox;

  final Box<Map> _transactionBox;

  @override
  List<Transaction> getByEventId(String eventId) {
    return _transactionBox.values
        .map((raw) => Transaction.fromMap(_castMap(raw)))
        .where((t) => t.eventId == eventId && t.deletedAt == null)
        .toList(growable: false);
  }

  @override
  void upsert(Transaction tx) {
    _transactionBox.put(tx.id, tx.toMap());
  }

  @override
  void delete(String txId) {
    final current = _transactionBox.get(txId);
    if (current == null) return;
    final now = DateTime.now();
    final currentTx = Transaction.fromMap(_castMap(current), id: txId);
    _transactionBox.put(
      txId,
      currentTx.copyWith(deletedAt: now, updatedAt: now).toMap(),
    );
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
