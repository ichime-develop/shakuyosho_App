import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/friend_model.dart';
import 'package:shakuyousho_app/domain/repositories/friend_repository.dart';

/// Hive-backed implementation for Friend persistence (Map storage).
class HiveFriendRepository implements FriendRepository {
  HiveFriendRepository({required Box<Map> friendBox}) : _friendBox = friendBox;

  final Box<Map> _friendBox;

  @override
  Future<List<Friend>> getAll() async {
    final friends = _friendBox.values
        .map((raw) => Friend.fromMap(_castMap(raw)))
        .where((f) => f.deletedAt == null)
        .toList()
      ..sort((a, b) => a.userId.compareTo(b.userId));
    return friends;
  }

  @override
  Future<void> add(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    final raw = _friendBox.get(trimmed);
    if (raw == null) {
      final friend = Friend(
        userId: trimmed,
        createdAt: DateTime.now(),
      );
      _friendBox.put(trimmed, friend.toMap());
      return;
    }
    final existing = Friend.fromMap(_castMap(raw), userId: trimmed);
    if (existing.deletedAt == null) return;
    final revived = existing.copyWith(deletedAt: null);
    _friendBox.put(trimmed, revived.toMap());
  }

  @override
  Future<void> remove(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    final raw = _friendBox.get(trimmed);
    if (raw == null) return;
    final existing = Friend.fromMap(_castMap(raw), userId: trimmed);
    if (existing.deletedAt != null) return;
    _friendBox.put(
      trimmed,
      existing.copyWith(deletedAt: DateTime.now()).toMap(),
    );
  }

  @override
  Future<List<Friend>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    final friends = _friendBox.values
        .map((raw) => Friend.fromMap(_castMap(raw)))
        .where((f) => f.deletedAt == null)
        .where((f) => f.userId.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.userId.compareTo(b.userId));
    return friends;
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
