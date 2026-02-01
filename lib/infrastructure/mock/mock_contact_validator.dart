// Mock データ整合性バリデーター
// - contacts と users の整合性を検証
// - アプリ起動時またはリポジトリ初期化時に一度だけ呼び出す想定
// NOTE: 本番データ（Hive/Firebase）へ移行した後は不要になる想定。
//       開発・デモ用のモックデータを使う場合のみ残す。

import 'package:shakuyousho_app/data/mock/contacts_mock.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';

/// contacts_mock と users_mock の整合性を検証
/// 問題があれば AssertionError をスローする
void validateMockContacts() {
  final errors = <String>[];

  for (final contact in mockContacts) {
    // ownerUserId が users に存在するか
    if (!mockUsersById.containsKey(contact.ownerUserId)) {
      errors.add(
        'Contact ownerUserId "${contact.ownerUserId}" が users_mock に存在しません',
      );
    }

    // peerUserId が users に存在するか
    if (!mockUsersById.containsKey(contact.peerUserId)) {
      errors.add(
        'Contact peerUserId "${contact.peerUserId}" が users_mock に存在しません',
      );
    }

    // 自分自身を友達にしていないか
    if (contact.ownerUserId == contact.peerUserId) {
      errors.add(
        'Contact の ownerUserId と peerUserId が同一です: "${contact.ownerUserId}"',
      );
    }
  }

  // currentUserId が users に存在するか
  if (!mockUsersById.containsKey(currentUserId)) {
    errors.add('currentUserId "$currentUserId" が users_mock に存在しません');
  }

  if (errors.isNotEmpty) {
    throw AssertionError(
      'Mock データ整合性エラー:\n${errors.map((e) => '  - $e').join('\n')}',
    );
  }
}

/// 簡易検証（assert で使用）
bool get isMockContactsValid {
  try {
    validateMockContacts();
    return true;
  } catch (_) {
    return false;
  }
}
