import 'package:shakuyousho_app/domain/models/transaction_model.dart';

/// 取引データへのアクセスを抽象化するリポジトリインターフェース
abstract class TransactionRepository {
  /// イベントIDに紐づく取引一覧を取得
  List<Transaction> getByEventId(String eventId);

  /// 取引を作成または更新
  void upsert(Transaction tx);

  /// 取引を削除（論理削除）
  void delete(String txId);
}
