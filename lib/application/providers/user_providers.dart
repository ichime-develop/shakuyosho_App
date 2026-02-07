import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shakuyousho_app/infrastructure/mock/mock_user_mapper.dart'
    as mock_user_mapper;
import 'package:shakuyousho_app/infrastructure/repositories/hive_user_repository.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';
import 'package:shakuyousho_app/domain/repositories/user_repository.dart';

export 'package:shakuyousho_app/domain/models/user_model.dart';

// ────────────────────────────────────────────────────────────────
// 現在のログインユーザーID
// ────────────────────────────────────────────────────────────────
// TODO: Firebase Auth 導入後は FirebaseAuth.instance.currentUser!.uid に差し替え
const String currentUserId = 'u_001';

// ────────────────────────────────────────────────────────────────
// UserListNotifier（StateNotifier + UserRepository）
// ────────────────────────────────────────────────────────────────

class UserListNotifier extends StateNotifier<List<User>>
    implements UserRepository {
  UserListNotifier({
    required UserRepository userRepository,
    required List<User> initialUsers,
  }) : _userRepository = userRepository,
       super(List<User>.from(initialUsers));

  final UserRepository _userRepository;

  @override
  List<User> getAll() =>
      List.unmodifiable(state.where((u) => u.deletedAt == null));

  @override
  User? getById(String userId) {
    for (final user in state) {
      if (user.id == userId && user.deletedAt == null) return user;
    }
    return null;
  }

  @override
  void upsert(User user) {
    _userRepository.upsert(user);
    final updated = [...state];
    final index = updated.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      updated.add(user);
    } else {
      updated[index] = user;
    }
    state = updated;
  }
}

// ────────────────────────────────────────────────────────────────
// Hive ボックス・シード処理
// ────────────────────────────────────────────────────────────────

final Box<Map> _userBox = Hive.box<Map>('users');

/// モックユーザーの初期投入
final List<User> _mockUsers = List<User>.from(mock_user_mapper.mockDomainUsers);

void _seedUsersIfEmpty(Box<Map> box) {
  if (box.isNotEmpty) return;
  for (final user in _mockUsers) {
    box.put(user.id, user.toMap());
  }
}

final UserRepository _userRepo = HiveUserRepository(userBox: _userBox);

final List<User> _initialUsers = (() {
  _seedUsersIfEmpty(_userBox);
  return _userBox.values
      .map((raw) => User.fromMap(_castMap(raw)))
      .toList(growable: false);
})();

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

// ────────────────────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────────────────────

/// 全ユーザー一覧（StateNotifier）
/// - watch → 画面がユーザーデータ変更に自動追従
/// - notifier → upsert/getById などの操作
final userListProvider = StateNotifierProvider<UserListNotifier, List<User>>((
  ref,
) {
  return UserListNotifier(
    userRepository: _userRepo,
    initialUsers: _initialUsers,
  );
});

/// UserRepository として公開（書き込み操作用）
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return ref.read(userListProvider.notifier);
});

/// ユーザーIDから表示名を引くProvider（全画面で使用）
/// userListProvider を watch しているため、名前変更が自動で全画面に伝播する
final userDisplayNameProvider = Provider.family<String, String>((ref, userId) {
  final users = ref.watch(userListProvider);
  for (final u in users) {
    if (u.id == userId && u.deletedAt == null) return u.displayName;
  }
  return userId; // フォールバック: IDをそのまま返す
});

/// 現在のログインユーザー情報
final currentUserProvider = Provider<User?>((ref) {
  final users = ref.watch(userListProvider);
  for (final user in users) {
    if (user.id == currentUserId && user.deletedAt == null) {
      return user;
    }
  }
  return null;
});

/// 現在のユーザーID Provider
/// 将来Firebase Auth移行時にはここだけ差し替えればOK
final currentUserIdProvider = Provider<String>((ref) {
  return currentUserId;
});
