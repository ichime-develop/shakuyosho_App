import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/contacts_mock.dart';
import 'package:shakuyousho_app/domain/models/friend_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/friend_repository.dart';
import 'package:shakuyousho_app/domain/repositories/user_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/hive_friend_repository.dart';

export 'package:shakuyousho_app/domain/models/friend_model.dart';

// ────────────────────────────────────────────────────────────────
// AddFriendResult（エラーハンドリング用）
// ────────────────────────────────────────────────────────────────

/// 友達追加の結果
enum AddFriendResult {
  /// 追加成功
  success,

  /// コードに該当するユーザーが見つからない
  notFound,

  /// 自分自身のコード
  selfAdd,

  /// すでに友達
  alreadyFriend,
}

// ────────────────────────────────────────────────────────────────
// Hive ボックス & シード
// ────────────────────────────────────────────────────────────────

final Box<Map> _friendBox = Hive.box<Map>('friends');
final Box<Map> _threadBox = Hive.box<Map>('threads');
final Box<Map> _userBox = Hive.box<Map>('users');

void _seedFriendsIfEmpty({required Box<Map> box}) {
  final hasLive = box.values.any(
    (raw) => Friend.fromMap(_castMap(raw)).deletedAt == null,
  );
  if (hasLive) return;
  final userIds = _userIdsFromBox(_userBox);
  final createdAtByUserId = _friendCreatedAtFromThreads(_threadBox);

  for (final entry in createdAtByUserId.entries) {
    final userId = entry.key;
    if (!userIds.contains(userId)) continue;
    final friend = Friend(userId: userId, createdAt: entry.value);
    box.put(friend.userId, friend.toMap());
  }

  if (box.isNotEmpty) return;
  // フォールバック（threads未投入時）: contacts_mock に寄せる
  for (final contact in mockContacts) {
    if (contact.ownerUserId != currentUserId) continue;
    if (!userIds.contains(contact.peerUserId)) continue;
    final friend = Friend(
      userId: contact.peerUserId,
      createdAt: contact.createdAt ?? DateTime(2024, 1, 1),
    );
    box.put(friend.userId, friend.toMap());
  }
}

// ────────────────────────────────────────────────────────────────
// Repository Provider
// ────────────────────────────────────────────────────────────────

/// FriendRepository（Map保存）
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  ref.read(userListProvider);
  ref.read(threadListProvider);
  _seedFriendsIfEmpty(box: _friendBox);
  return HiveFriendRepository(friendBox: _friendBox);
});

// ────────────────────────────────────────────────────────────────
// Friend Providers
// ────────────────────────────────────────────────────────────────

/// 全友達一覧
final allFriendsProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getAll();
});

/// 友達検索
final friendSearchProvider = FutureProvider.family<List<Friend>, String>((
  ref,
  query,
) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.search(query);
});

// ────────────────────────────────────────────────────────────────
// Friend Actions（状態変更用）
// ────────────────────────────────────────────────────────────────

/// 友達の操作を行うNotifier
class FriendActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  FriendRepository get _repo => ref.read(friendRepositoryProvider);
  UserRepository get _userRepo => ref.read(userRepositoryProvider);

  /// 友達コードで追加（コード入力/リンク/QR共通）
  Future<AddFriendResult> addFriendByCode(
    String code, {
    required String source,
  }) async {
    final peer = _userRepo.getByCode(code);
    if (peer == null) return AddFriendResult.notFound;
    if (peer.id == currentUserId) return AddFriendResult.selfAdd;

    // 既に友達かチェック
    final friends = await _repo.getAll();
    if (friends.any((f) => f.userId == peer.id)) {
      return AddFriendResult.alreadyFriend;
    }

    await _repo.addWithSource(peer.id, source: source);
    _invalidateAll();
    return AddFriendResult.success;
  }

  /// 友達を追加（既存：名前 or ID入力）
  Future<void> addFriend(String input) async {
    final resolved = _resolveUserId(input);
    if (resolved == null) return;
    await _repo.add(resolved);
    _invalidateAll();
  }

  /// 友達を削除
  Future<void> removeFriend(String input) async {
    final resolved = _resolveUserId(input);
    if (resolved == null) return;
    await _repo.remove(resolved);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidate(allFriendsProvider);
  }

  String? _resolveUserId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final direct = _userRepo.getById(trimmed);
    if (direct != null) return direct.id;
    for (final user in _userRepo.getAll()) {
      if (user.displayName == trimmed) return user.id;
    }
    return null;
  }
}

final friendActionsProvider = NotifierProvider<FriendActionsNotifier, void>(
  FriendActionsNotifier.new,
);

// ────────────────────────────────────────────────────────────────
// ヘルパー関数
// ────────────────────────────────────────────────────────────────

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

Set<String> _userIdsFromBox(Box<Map> userBox) {
  return userBox.values
      .map((raw) => User.fromMap(_castMap(raw)))
      .where((u) => u.deletedAt == null)
      .map((u) => u.id)
      .where((id) => id.isNotEmpty)
      .toSet();
}

Map<String, DateTime> _friendCreatedAtFromThreads(Box<Map> threadBox) {
  final createdAtByUserId = <String, DateTime>{};
  for (final raw in threadBox.values) {
    final thread = Thread.fromMap(_castMap(raw));
    if (thread.deletedAt != null) continue;
    if (thread.type != 'personal') continue;
    if (!thread.participantIds.contains(currentUserId)) continue;
    final peer = thread.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (peer.isEmpty) continue;
    final existing = createdAtByUserId[peer];
    if (existing == null || thread.createdAt.isBefore(existing)) {
      createdAtByUserId[peer] = thread.createdAt;
    }
  }
  return createdAtByUserId;
}
