import 'package:hive/hive.dart';

part 'thread_model.g.dart';

// スレッド（会話/グループ）の情報を表すモデル。
@HiveType(typeId: 4)
class Thread {
  Thread({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String type; // e.g. 'group'
  @HiveField(2)
  final String title;
  @HiveField(3)
  final List<String> participantIds;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
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
