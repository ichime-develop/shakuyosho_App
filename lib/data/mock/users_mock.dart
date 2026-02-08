/// 全ユーザーDB（Firebase users コレクションの代替）
/// - 友達だけでなく、全ユーザーを含む
/// - 友達かどうかは contacts_mock で管理
class MockUser {
  const MockUser({
    required this.userId,
    required this.displayName,
    required this.myCode,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String myCode;
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
  MockUser(userId: 'u_001', displayName: 'いちかわけいた', myCode: 'SYY-K1A0X'),

  // 友達（contacts_mock に登録されるユーザー）
  MockUser(userId: 'u_002', displayName: 'ゆうき', myCode: 'SYY-Y2B1K'),
  MockUser(userId: 'u_003', displayName: 'まな', myCode: 'SYY-M3C2N'),
  MockUser(userId: 'u_004', displayName: 'けんた', myCode: 'SYY-K4D3T'),
  MockUser(userId: 'u_005', displayName: 'みさき', myCode: 'SYY-M5E4S'),
  MockUser(userId: 'u_006', displayName: 'あやこ', myCode: 'SYY-A6F5Y'),
  MockUser(userId: 'u_007', displayName: 'なおき', myCode: 'SYY-N7G6K'),
  MockUser(userId: 'u_008', displayName: 'さとる', myCode: 'SYY-S8H7R'),
  MockUser(userId: 'u_009', displayName: 'りえ', myCode: 'SYY-R9J8E'),
  MockUser(userId: 'u_010', displayName: 'ごう', myCode: 'SYY-G0K9U'),
  MockUser(userId: 'u_011', displayName: 'ひろし', myCode: 'SYY-H1L0S'),
  MockUser(userId: 'u_012', displayName: 'かおり', myCode: 'SYY-K2M1R'),

  // 友達ではないユーザー（フィルタ検証用）
  MockUser(userId: 'u_013', displayName: 'たかし', myCode: 'SYY-T3N2S'),
  MockUser(userId: 'u_014', displayName: 'さくら', myCode: 'SYY-S4P3R'),
  MockUser(userId: 'u_015', displayName: 'ゆうた', myCode: 'SYY-Y5Q4T'),
  MockUser(userId: 'u_016', displayName: 'れいな', myCode: 'SYY-R6R5N'),
  MockUser(userId: 'u_017', displayName: 'こうじ', myCode: 'SYY-K7S6J'),
  MockUser(userId: 'u_018', displayName: 'みゆき', myCode: 'SYY-M8T7K'),
  MockUser(userId: 'u_019', displayName: 'だいすけ', myCode: 'SYY-D9U8K'),
  MockUser(userId: 'u_020', displayName: 'あかね', myCode: 'SYY-A0V9N'),
  MockUser(userId: 'u_021', displayName: 'しんじ', myCode: 'SYY-S1W0J'),
  MockUser(userId: 'u_022', displayName: 'なつみ', myCode: 'SYY-N2X1M'),
  MockUser(userId: 'u_023', displayName: 'けいすけ', myCode: 'SYY-K3Y2S'),
  MockUser(userId: 'u_024', displayName: 'ゆりか', myCode: 'SYY-Y4Z3K'),
  MockUser(userId: 'u_025', displayName: 'たくや', myCode: 'SYY-T5A4Y'),
  MockUser(userId: 'u_026', displayName: 'さやか', myCode: 'SYY-S6B5K'),
  MockUser(userId: 'u_027', displayName: 'りょうた', myCode: 'SYY-R7C6T'),
  MockUser(userId: 'u_028', displayName: 'ももこ', myCode: 'SYY-M8D7K'),
  MockUser(userId: 'u_029', displayName: 'しゅんすけ', myCode: 'SYY-S9E8K'),
  MockUser(userId: 'u_030', displayName: 'あすか', myCode: 'SYY-A0F9K'),
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

/// モックデータ生成用（画面表示では使用しない）
String mockDisplayNameOf(String userId) {
  final user = mockUsersById[userId];
  assert(user != null, 'Unknown userId referenced in mock data: $userId');
  return user?.displayName ?? '???';
}
