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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory EventMeta.fromJson(Map<String, dynamic> json) {
    return EventMeta(
      id: json['id'] as String,
      title: json['title'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }
}
