/// 友達（坂口モデル準拠）
/// - userId で管理
/// - Loan の counterpartyId と紐づく
class Friend {
  final String userId;
  final DateTime createdAt;
  final DateTime? deletedAt;

  /// 友達追加の経路（'code' / 'link' / 'qr' / null=既存）
  final String? source;

  const Friend({
    required this.userId,
    required this.createdAt,
    this.deletedAt,
    this.source,
  });

  Friend copyWith({
    String? userId,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? source,
  }) {
    return Friend(
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Friend &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'Friend(userId: $userId, createdAt: $createdAt)';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
      'source': source,
    };
  }

  factory Friend.fromMap(Map<dynamic, dynamic> map, {String? userId}) {
    final resolvedId = userId ?? map['userId'] as String? ?? '';
    return Friend(
      userId: resolvedId,
      createdAt: _dateFrom(map['createdAtMs'] ?? map['createdAt']),
      deletedAt: _dateFromNullable(map['deletedAtMs'] ?? map['deletedAt']),
      source: map['source'] as String?,
    );
  }
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
  return _dateFrom(raw);
}
