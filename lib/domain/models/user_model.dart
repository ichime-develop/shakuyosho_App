// アプリ内ユーザーの基本情報を表すモデル。
class User {
  User({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  User copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAtMs': createdAt?.millisecondsSinceEpoch,
      'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    return User(
      id: resolvedId,
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: _dateFromNullable(map['createdAtMs'] ?? map['createdAt']),
      deletedAt: _dateFromNullable(map['deletedAtMs'] ?? map['deletedAt']),
    );
  }
}

DateTime? _dateFromNullable(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
