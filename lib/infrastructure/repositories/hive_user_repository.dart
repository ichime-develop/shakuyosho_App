import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';
import 'package:shakuyousho_app/domain/repositories/user_repository.dart';

/// Hive-backed implementation for User persistence.
class HiveUserRepository implements UserRepository {
  HiveUserRepository({required Box<User> userBox}) : _userBox = userBox;

  final Box<User> _userBox;

  @override
  List<User> getAll() => _userBox.values.toList(growable: false);

  @override
  User? getById(String userId) => _userBox.get(userId);

  @override
  void upsert(User user) {
    _userBox.put(user.id, user);
  }
}
