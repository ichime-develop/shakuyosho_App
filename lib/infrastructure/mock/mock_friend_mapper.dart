// 友達表示用のビューモデル（contacts + users の join 結果）
// - infrastructure 層で contacts と users を結合
// - 画面は mock ファイルを直接参照しない

import 'package:shakuyousho_app/data/mock/contacts_mock.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';

/// 友達表示用ビューモデル
/// contacts と users を join した結果
class FriendView {
  const FriendView({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  /// ユーザーID
  final String userId;

  /// 表示名（users.displayName）
  final String displayName;

  /// アバターURL（任意）
  final String? avatarUrl;

  /// 友達登録日時
  final DateTime createdAt;
}

/// 指定した ownerUserId の友達一覧を取得
/// contacts → users の順で参照し、表示名を解決
List<FriendView> getFriendUsersFor(String ownerUserId) {
  final contacts = mockContacts
      .where((c) => c.ownerUserId == ownerUserId)
      .toList();

  final result = <FriendView>[];
  for (final contact in contacts) {
    final user = mockUsersById[contact.peerUserId];
    if (user == null) {
      // バリデーションで防止されているはずだが、念のためスキップ
      continue;
    }

    result.add(
      FriendView(
        userId: user.userId,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        createdAt: contact.createdAt ?? DateTime(2024, 1, 1),
      ),
    );
  }

  return result;
}

/// 現在ログインユーザーの友達一覧を取得（簡易版）
List<FriendView> getCurrentUserFriends() {
  return getFriendUsersFor(currentUserId);
}

/// 指定した peerUserId が友達かどうかを判定
bool isFriend(String peerUserId) {
  return mockContactPeerIds.contains(peerUserId);
}

/// 指定した peerUserId の表示名を取得
/// users.displayName を使用
String getDisplayNameFor(String peerUserId) {
  return mockUsersById[peerUserId]?.displayName ?? '???';
}
