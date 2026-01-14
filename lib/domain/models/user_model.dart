class User {
  User({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final DateTime? createdAt;

  User copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
