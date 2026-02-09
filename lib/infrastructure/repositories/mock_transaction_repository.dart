import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';

/// Mock implementation backed by domain transactions.
/// NOTE: 現在はHive実装に切替済みのため未使用。テストや比較用に保持。
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository(List<Transaction> initial)
    : _txs = List<Transaction>.from(initial);

  final List<Transaction> _txs;

  @override
  Future<List<Transaction>> getAll() async {
    try {
      return List<Transaction>.unmodifiable(_txs);
    } catch (e, st) {
      throw AppError(
        type: AppErrorType.unknown,
        userMessage: '',
        message: 'transaction get all failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<Transaction>> getByEventId(String eventId) async {
    try {
      return _txs
          .where((t) => t.eventId == eventId && t.deletedAt == null)
          .toList(growable: false);
    } catch (e, st) {
      throw AppError(
        type: AppErrorType.unknown,
        userMessage: '',
        message: 'transaction get failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> upsert(Transaction tx) async {
    try {
      final idx = _txs.indexWhere((t) => t.id == tx.id);
      if (idx == -1) {
        _txs.add(tx);
      } else {
        _txs[idx] = tx;
      }
    } catch (e, st) {
      throw AppError(
        type: AppErrorType.unknown,
        userMessage: '',
        message: 'transaction upsert failed',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> delete(String txId) async {
    try {
      final now = DateTime.now();
      final index = _txs.indexWhere((t) => t.id == txId);
      if (index == -1) return;
      final current = _txs[index];
      _txs[index] = current.copyWith(deletedAt: now, updatedAt: now);
    } catch (e, st) {
      throw AppError(
        type: AppErrorType.unknown,
        userMessage: '',
        message: 'transaction delete failed',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
