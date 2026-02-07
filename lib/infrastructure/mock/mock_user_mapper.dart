import 'package:shakuyousho_app/data/mock/users_mock.dart' as users_mock;
import 'package:shakuyousho_app/domain/models/user_model.dart' as domain_user;

/// Mockの生データをドメインモデルに変換するためのマッパー。
/// NOTE: 本番データ（Hive/Firebase）へ移行した後は不要になる想定。
///       開発・デモ用のモックデータを使う場合のみ残す。
domain_user.User toDomainUser(users_mock.MockUser user) {
  return domain_user.User(
    id: user.userId,
    displayName: user.displayName,
    myCode: user.myCode,
    avatarUrl: user.avatarUrl,
    createdAt: null,
  );
}

/// Mockの全ユーザーデータをドメインモデルへ一括変換。
final List<domain_user.User> mockDomainUsers =
    List<domain_user.User>.unmodifiable(
      users_mock.mockUsers.map(toDomainUser).toList(growable: false),
    );
