import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/data/mock/contacts_mock.dart' as contacts_mock;
import 'package:shakuyousho_app/data/mock/threads_mock.dart' as threads_mock;
import 'package:shakuyousho_app/data/mock/users_mock.dart' as users_mock;
import 'package:shakuyousho_app/domain/models/thread_model.dart';

class PersonalThreadSummary {
  const PersonalThreadSummary({
    required this.threadId,
    required this.displayName,
    required this.updatedAt,
    required this.updatedAtLabel,
  });

  final String threadId;
  final String displayName;
  final DateTime updatedAt;
  final String updatedAtLabel;
}

class GroupThreadSummary {
  const GroupThreadSummary({
    required this.threadId,
    required this.groupName,
    required this.memberCount,
    required this.updatedAt,
    required this.updatedAtLabel,
  });

  final String threadId;
  final String groupName;
  final int memberCount;
  final DateTime updatedAt;
  final String updatedAtLabel;
}

class ThreadDetailView {
  const ThreadDetailView({
    required this.thread,
    required this.title,
    required this.isGroup,
    required this.memberCount,
    this.peerUserId,
  });

  final Thread thread;
  final String title;
  final bool isGroup;
  final int memberCount;
  final String? peerUserId;
}

final personalThreadsProvider = Provider<List<PersonalThreadSummary>>((ref) {
  final results = <PersonalThreadSummary>[];
  final contacts = contacts_mock.mockContacts
      .where((c) => c.ownerUserId == users_mock.currentUserId)
      .toList(growable: false);

  for (final contact in contacts) {
    final peerId = contact.peerUserId;
    final user = users_mock.mockUsersById[peerId];
    final displayName = user?.displayName ?? '???';
    final thread = _findPersonalThread(peerId);
    final updatedAt = thread?.updatedAt ?? contact.createdAt ?? _fallbackDate();
    final threadId = thread?.id ?? _virtualThreadId(peerId);

    results.add(
      PersonalThreadSummary(
        threadId: threadId,
        displayName: displayName,
        updatedAt: updatedAt,
        updatedAtLabel: _formatDateTime(updatedAt),
      ),
    );
  }

  results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return List.unmodifiable(results);
});

final groupThreadsProvider = Provider<List<GroupThreadSummary>>((ref) {
  final results = threads_mock.mockThreads
      .where((t) => t.type == 'group')
      .map(
        (t) => GroupThreadSummary(
          threadId: t.id,
          groupName: t.title,
          memberCount: t.participantIds.length,
          updatedAt: t.updatedAt,
          updatedAtLabel: _formatDateTime(t.updatedAt),
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return results;
});

final threadDetailProvider = Provider.family<ThreadDetailView?, String>((
  ref,
  threadId,
) {
  Thread? thread = _findThreadById(threadId);
  thread ??= _buildVirtualPersonalThread(threadId);
  if (thread == null) return null;

  final isGroup = thread.type == 'group';
  final memberCount = thread.participantIds.length;
  String? peerUserId;
  String title;
  if (isGroup) {
    title = thread.title;
  } else {
    peerUserId = _resolvePeerUserId(thread.participantIds);
    title =
        peerUserId == null ? thread.title : _displayNameFor(peerUserId) ?? '???';
  }

  return ThreadDetailView(
    thread: thread,
    title: title,
    isGroup: isGroup,
    memberCount: memberCount,
    peerUserId: peerUserId,
  );
});

Thread? _findThreadById(String threadId) {
  for (final thread in threads_mock.mockThreads) {
    if (thread.id == threadId) return thread;
  }
  return null;
}

Thread? _findPersonalThread(String peerUserId) {
  for (final thread in threads_mock.mockThreads) {
    if (thread.type == 'group') continue;
    final ids = thread.participantIds;
    if (ids.contains(users_mock.currentUserId) && ids.contains(peerUserId)) {
      return thread;
    }
  }
  return null;
}

Thread? _buildVirtualPersonalThread(String threadId) {
  if (!threadId.startsWith('virtual_personal_')) return null;
  final peerUserId = threadId.replaceFirst('virtual_personal_', '');
  if (!users_mock.mockUsersById.containsKey(peerUserId)) return null;
  return Thread(
    id: threadId,
    type: 'personal',
    title: _displayNameFor(peerUserId) ?? '???',
    participantIds: [users_mock.currentUserId, peerUserId],
    createdAt: _fallbackDate(),
    updatedAt: _fallbackDate(),
  );
}

String _virtualThreadId(String peerUserId) => 'virtual_personal_$peerUserId';

String? _displayNameFor(String userId) =>
    users_mock.mockUsersById[userId]?.displayName;

String? _resolvePeerUserId(List<String> participantIds) {
  for (final id in participantIds) {
    if (id != users_mock.currentUserId) return id;
  }
  return null;
}

DateTime _fallbackDate() => DateTime(2024, 1, 1, 12, 0);

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y/$m/$d $h:$min';
}
