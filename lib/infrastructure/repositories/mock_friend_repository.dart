import '../../data/mock/contacts_mock.dart';
import '../../data/mock/users_mock.dart';
import '../../domain/models/friend_model.dart';
import '../../domain/repositories/friend_repository.dart';

/// FriendRepositoryのMock実装
class MockFriendRepository implements FriendRepository {
  MockFriendRepository({List<MockContact>? initialContacts})
    : _contacts = List<MockContact>.from(
        initialContacts ?? mockContacts,
      );

  final List<MockContact> _contacts;

  @override
  Future<List<Friend>> getAll() async {
    final friends = _contacts
        .where((c) => c.ownerUserId == currentUserId)
        .map(
          (c) => Friend(
            userId: c.peerUserId,
            createdAt: c.createdAt ?? DateTime(2024, 1, 1),
          ),
        )
        .toList();
    friends.sort(
      (a, b) => _displayNameOf(a.userId).compareTo(_displayNameOf(b.userId)),
    );
    return friends;
  }

  @override
  Future<void> add(String userId) async {
    final resolved = _resolveUserId(userId);
    if (resolved == null) return;
    final exists = _contacts.any(
      (c) => c.ownerUserId == currentUserId && c.peerUserId == resolved,
    );
    if (exists) return;
    _contacts.add(
      MockContact(
        ownerUserId: currentUserId,
        peerUserId: resolved,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> remove(String userId) async {
    final resolved = _resolveUserId(userId);
    if (resolved == null) return;
    _contacts.removeWhere(
      (c) => c.ownerUserId == currentUserId && c.peerUserId == resolved,
    );
  }

  @override
  Future<List<Friend>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();

    final friends = _contacts
        .where((c) => c.ownerUserId == currentUserId)
        .where((c) {
          final displayName = _displayNameOf(c.peerUserId).toLowerCase();
          return displayName.contains(q) ||
              c.peerUserId.toLowerCase().contains(q);
        })
        .map(
          (c) => Friend(
            userId: c.peerUserId,
            createdAt: c.createdAt ?? DateTime(2024, 1, 1),
          ),
        )
        .toList();
    friends.sort(
      (a, b) => _displayNameOf(a.userId).compareTo(_displayNameOf(b.userId)),
    );
    return friends;
  }

  String _displayNameOf(String userId) {
    return mockUsersById[userId]?.displayName ?? userId;
  }

  String? _resolveUserId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (mockUsersById.containsKey(trimmed)) return trimmed;
    final lower = trimmed.toLowerCase();
    for (final user in mockUsers) {
      if (user.displayName.toLowerCase() == lower) return user.userId;
    }
    return null;
  }
}
