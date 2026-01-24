// 自分の友達リスト（Firebase contacts サブコレクションの代替）
// - ownerUserId が持つ連絡先（peerUserId）のみ
// - FR0100/FR0200 は contacts → users の順で参照
// - 表示名は users.displayName を使用

import 'users_mock.dart';

/// 友達（コンタクト）モデル
class MockContact {
  const MockContact({
    required this.ownerUserId,
    required this.peerUserId,
    this.createdAt,
  });

  /// このコンタクトを所有するユーザーID（常に currentUserId）
  final String ownerUserId;

  /// 友達のユーザーID
  final String peerUserId;

  /// 友達登録日時（任意）
  final DateTime? createdAt;
}

/// 自分（u_001）の友達リスト
/// - 8〜15件程度
/// - peerUserId は全て users_mock に存在すること
final List<MockContact> mockContacts = [
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_002',
    createdAt: DateTime(2024, 1, 15),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_003',
    createdAt: DateTime(2024, 2, 10),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_004',
    createdAt: DateTime(2024, 3, 5),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_005',
    createdAt: DateTime(2024, 3, 20),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_006',
    createdAt: DateTime(2024, 4, 1),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_007',
    createdAt: DateTime(2024, 4, 15),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_008',
    createdAt: DateTime(2024, 5, 10),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_009',
    createdAt: DateTime(2024, 6, 1),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_010',
    createdAt: DateTime(2024, 7, 20),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_011',
    createdAt: DateTime(2024, 8, 5),
  ),
  MockContact(
    ownerUserId: currentUserId,
    peerUserId: 'u_012',
    createdAt: DateTime(2024, 9, 15),
  ),
];

/// peerUserId で高速にコンタクトを引くためのSet
final Set<String> mockContactPeerIds = {
  for (final c in mockContacts) c.peerUserId,
};

/// peerUserId で MockContact を引くためのMap
final Map<String, MockContact> mockContactsByPeerId = {
  for (final c in mockContacts) c.peerUserId: c,
};
