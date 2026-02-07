import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';
import 'package:shakuyousho_app/domain/repositories/user_repository.dart';

/// Hive-backed implementation for User persistence.
class HiveUserRepository implements UserRepository {
  HiveUserRepository({required Box<Map> userBox}) : _userBox = userBox;

  final Box<Map> _userBox;

  @override
  List<User> getAll() => _userBox.values
      .map((raw) => User.fromMap(_castMap(raw)))
      .where((u) => u.deletedAt == null)
      .toList(growable: false);

  @override
  User? getById(String userId) {
    final raw = _userBox.get(userId);
    if (raw == null) return null;
    final user = User.fromMap(_castMap(raw), id: userId);
    return user.deletedAt == null ? user : null;
  }

  @override
  User? getByCode(String code) {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    for (final raw in _userBox.values) {
      final user = User.fromMap(_castMap(raw));
      if (user.deletedAt != null) continue;
      if (user.myCode?.toUpperCase() == trimmed) return user;
    }
    return null;
  }

  @override
  void upsert(User user) {
    _userBox.put(user.id, user.toMap());
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
