/// 全ユーザーDB（Firebase users コレクションの代替）
/// - 友達だけでなく、全ユーザーを含む
/// - 友達かどうかは contacts_mock で管理
class MockUser {
  const MockUser({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
}

/// 現在ログイン中のユーザーID
const String currentUserId = 'u_001';

/// 全ユーザー一覧（20〜50人）
/// - u_001 は自分（self）
/// - contacts_mock に含まれる peerUserId は必ずここに存在する
/// - 友達ではないユーザーも含む（友達フィルタ検証用）
const List<MockUser> mockUsers = [
  // 自分
  MockUser(userId: 'u_001', displayName: 'いちかわけいた'),

  // 友達（contacts_mock に登録されるユーザー）
  MockUser(userId: 'u_002', displayName: 'ゆうき'),
  MockUser(userId: 'u_003', displayName: 'まな'),
  MockUser(userId: 'u_004', displayName: 'けんた'),
  MockUser(userId: 'u_005', displayName: 'みさき'),
  MockUser(userId: 'u_006', displayName: 'あやこ'),
  MockUser(userId: 'u_007', displayName: 'なおき'),
  MockUser(userId: 'u_008', displayName: 'さとる'),
  MockUser(userId: 'u_009', displayName: 'りえ'),
  MockUser(userId: 'u_010', displayName: 'ごう'),
  MockUser(userId: 'u_011', displayName: 'ひろし'),
  MockUser(userId: 'u_012', displayName: 'かおり'),

  // 友達ではないユーザー（フィルタ検証用）
  MockUser(userId: 'u_013', displayName: 'たかし'),
  MockUser(userId: 'u_014', displayName: 'さくら'),
  MockUser(userId: 'u_015', displayName: 'ゆうた'),
  MockUser(userId: 'u_016', displayName: 'れいな'),
  MockUser(userId: 'u_017', displayName: 'こうじ'),
  MockUser(userId: 'u_018', displayName: 'みゆき'),
  MockUser(userId: 'u_019', displayName: 'だいすけ'),
  MockUser(userId: 'u_020', displayName: 'あかね'),
  MockUser(userId: 'u_021', displayName: 'しんじ'),
  MockUser(userId: 'u_022', displayName: 'なつみ'),
  MockUser(userId: 'u_023', displayName: 'けいすけ'),
  MockUser(userId: 'u_024', displayName: 'ゆりか'),
  MockUser(userId: 'u_025', displayName: 'たくや'),
  MockUser(userId: 'u_026', displayName: 'さやか'),
  MockUser(userId: 'u_027', displayName: 'りょうた'),
  MockUser(userId: 'u_028', displayName: 'ももこ'),
  MockUser(userId: 'u_029', displayName: 'しゅんすけ'),
  MockUser(userId: 'u_030', displayName: 'あすか'),
];

/// ユーザーIDでユーザーを引くためのMap
final Map<String, MockUser> mockUsersById = {
  for (final u in mockUsers) u.userId: u,
};

/// ユーザーIDから表示名を取得（互換用）
/// 画面での名前表示には userDisplayNameProvider を使用すること。
/// この関数はモックデータ初期化専用として残す。
@Deprecated('画面表示には userDisplayNameProvider を使用してください')
String displayNameOf(String userId) {
  final user = mockUsersById[userId];
  assert(user != null, 'Unknown userId referenced in mock data: $userId');
  return user?.displayName ?? '???';
}
