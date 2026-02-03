// スレッド（会話/グループ）の情報を表すモデル。
class Thread {
  Thread({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String type; // e.g. 'group'
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Thread copyWith({
    String? id,
    String? type,
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Thread(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'participantIds': participantIds,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Thread.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    return Thread(
      id: resolvedId,
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      participantIds: _stringListFrom(map['participantIds']),
      createdAt: _dateFrom(map['createdAtMs'] ?? map['createdAt']),
      updatedAt: _dateFrom(map['updatedAtMs'] ?? map['updatedAt']),
      deletedAt: _dateFromNullable(map['deletedAtMs'] ?? map['deletedAt']),
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

List<String> _stringListFrom(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => '$e').toList(growable: false);
  }
  return const <String>[];
}
