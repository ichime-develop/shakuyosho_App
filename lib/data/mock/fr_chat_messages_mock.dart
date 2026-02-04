class MockChatMessage {
  const MockChatMessage({
    required this.friendId,
    required this.isMe,
    required this.text,
    required this.createdAt,
  });

  final String friendId;
  final bool isMe;
  final String text;
  final DateTime createdAt;
}

List<MockChatMessage> mockChatMessages({DateTime? now}) {
  final base = now ?? DateTime.now();
  return [
    MockChatMessage(
      friendId: 'u_002',
      isMe: false,
      text: 'この前の おこのみやき ありがとー',
      createdAt: base.subtract(const Duration(days: 2, hours: 3)),
    ),
    MockChatMessage(
      friendId: 'u_002',
      isMe: true,
      text: 'あとで まとめて で いいよ',
      createdAt: base.subtract(const Duration(days: 2, hours: 2)),
    ),
    MockChatMessage(
      friendId: 'u_003',
      isMe: false,
      text: 'でんしゃちん ちょっと たすかった',
      createdAt: base.subtract(const Duration(days: 6, hours: 1)),
    ),
    MockChatMessage(
      friendId: 'u_004',
      isMe: true,
      text: 'こんど まとめて へんさい するね',
      createdAt: base.subtract(const Duration(days: 3, hours: 4)),
    ),
  ];
}

List<MockChatMessage> chatMessagesFor(String friendId, {DateTime? now}) {
  return mockChatMessages(
    now: now,
  ).where((m) => m.friendId == friendId).toList(growable: false);
}
