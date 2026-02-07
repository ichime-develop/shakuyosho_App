import '../models/friend_model.dart';

/// 友達リポジトリのインターフェース
abstract class FriendRepository {
  /// 全件取得
  Future<List<Friend>> getAll();

  /// 追加
  Future<void> add(String userId);

  /// 追加（経路付き）
  Future<void> addWithSource(String userId, {String? source});

  /// 削除
  Future<void> remove(String userId);

  /// 検索（部分一致）
  Future<List<Friend>> search(String query);
}
