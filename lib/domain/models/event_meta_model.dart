// イベントの基本情報（メタデータ）を表すモデル。保存・一覧の基礎データ。
class EventMeta {
  EventMeta({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  EventMeta copyWith({
    String? id,
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EventMeta(
      id: id ?? this.id,
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
      'title': title,
      'participantIds': participantIds,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory EventMeta.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    final rawParticipants = map['participantIds'];
    final participants = rawParticipants is List
        ? rawParticipants.map((e) => '$e').toList(growable: false)
        : const <String>[];
    return EventMeta(
      id: resolvedId,
      title: map['title'] as String? ?? '',
      participantIds: participants,
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
