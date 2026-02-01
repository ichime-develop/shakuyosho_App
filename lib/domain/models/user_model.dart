import 'package:hive/hive.dart';

part 'user_model.g.dart';

// アプリ内ユーザーの基本情報を表すモデル。
@HiveType(typeId: 5)
class User {
  User({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String displayName;
  @HiveField(2)
  final String? avatarUrl;
  @HiveField(3)
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
