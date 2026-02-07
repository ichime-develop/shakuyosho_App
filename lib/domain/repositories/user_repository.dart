import 'package:shakuyousho_app/domain/models/user_model.dart';

/// ユーザーデータへのアクセスを抽象化するリポジトリインターフェース
abstract class UserRepository {
  /// すべてのユーザーを取得
  List<User> getAll();

  /// IDでユーザーを取得
  User? getById(String userId);

  /// 友達コードでユーザーを取得
  User? getByCode(String code);

  /// ユーザーを作成または更新
  void upsert(User user);
}
