import 'users_mock.dart';

class MockContact {
  const MockContact({
    required this.ownerUserId,
    required this.peerUserId,
    this.nickname,
  });

  final String ownerUserId;
  final String peerUserId;
  final String? nickname;
}

const String mockLoginUserId = 'u_001';

const List<MockContact> mockContacts = [
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_002', nickname: 'ゆう'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_003'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_004'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_005', nickname: 'みさ'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_006'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_007'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_008'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_009'),
  MockContact(ownerUserId: mockLoginUserId, peerUserId: 'u_010'),
];
