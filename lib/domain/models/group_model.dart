class Group {
  Group({
    required this.id,
    required this.title,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;

  Group copyWith({
    String? id,
    String? title,
    List<String>? memberIds,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      title: title ?? this.title,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
