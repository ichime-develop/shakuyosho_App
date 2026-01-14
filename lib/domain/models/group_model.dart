class Group {
  Group({
    required this.id,
    required this.title,
    required this.memberIds,
  });

  final String id;
  final String title;
  final List<String> memberIds;

  Group copyWith({
    String? id,
    String? title,
    List<String>? memberIds,
  }) {
    return Group(
      id: id ?? this.id,
      title: title ?? this.title,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
