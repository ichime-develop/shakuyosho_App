/// チャットメッセージ（坂口モデル準拠）
/// - threadId（= friendId）で友達との会話を特定
/// - senderId で送信者を識別
/// - 借用書とは独立した純粋なテキストメッセージ
class ChatMessage {
  final String id;
  final String threadId; // 1対1の場合は friendId と同値
  final String senderId; // 送信者のユーザーID
  final String text;
  final DateTime createdAt;
  final DateTime? deletedAt; // 論理削除

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.deletedAt,
  });

  /// 空メッセージ（ダミー用）
  factory ChatMessage.empty() => ChatMessage(
    id: '',
    threadId: '',
    senderId: '',
    text: '',
    createdAt: DateTime.now(),
    deletedAt: null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'threadId': threadId,
    'senderId': senderId,
    'text': text,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
    'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    return ChatMessage(
      id: resolvedId,
      threadId: (map['threadId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      createdAt: _dateFrom(map['createdAtMs'] ?? map['createdAt']),
      deletedAt: _dateFromNullable(map['deletedAtMs'] ?? map['deletedAt']),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: $id, threadId: $threadId, senderId: $senderId, text: $text)';
}

DateTime _dateFrom(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _dateFromNullable(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
