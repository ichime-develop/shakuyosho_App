// スレッド（会話/グループ）の情報を表すモデル。
class Thread {
  Thread({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type; // e.g. 'group'
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Thread copyWith({
    String? id,
    String? type,
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Thread(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
