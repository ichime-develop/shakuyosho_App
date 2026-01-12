class MockUser {
  const MockUser({required this.userId, required this.displayName});

  final String userId;
  final String displayName;
}

const List<MockUser> mockUsers = [
  MockUser(userId: 'u_001', displayName: 'いちか'),
  MockUser(userId: 'u_002', displayName: 'ゆうき'),
  MockUser(userId: 'u_003', displayName: 'まな'),
  MockUser(userId: 'u_004', displayName: 'けんた'),
  MockUser(userId: 'u_005', displayName: 'みさき'),
  MockUser(userId: 'u_006', displayName: 'あやこ'),
  MockUser(userId: 'u_007', displayName: 'なおき'),
  MockUser(userId: 'u_008', displayName: 'さとる'),
  MockUser(userId: 'u_009', displayName: 'りえ'),
  MockUser(userId: 'u_010', displayName: 'ごう'),
];

String displayNameOf(String userId) {
  return mockUsers
      .firstWhere(
        (u) => u.userId == userId,
        orElse: () => const MockUser(userId: 'unknown', displayName: '???'),
      )
      .displayName;
}
