import 'package:shakuyousho_app/domain/models/transaction_model.dart';

/// 取引データへのアクセスを抽象化するリポジトリインターフェース
abstract class TransactionRepository {
  /// すべての取引を取得
  Future<List<Transaction>> getAll();

  /// イベントIDに紐づく取引一覧を取得
  Future<List<Transaction>> getByEventId(String eventId);

  /// 取引を作成または更新
  Future<void> upsert(Transaction tx);

  /// 取引を削除（論理削除）
  Future<void> delete(String txId);
}
