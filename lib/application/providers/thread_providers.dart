import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
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

/// 1対1スレッド一覧（友達ごと）
/// - friendsProvider（Hive） + threadListProvider（Hive） + userListProvider を使用
/// - mock直接参照なし
final personalThreadsProvider = Provider<List<PersonalThreadSummary>>((ref) {
  final myId = ref.watch(currentUserIdProvider);
  final threads = ref.watch(threadListProvider);
  final friends = ref
      .watch(allFriendsProvider)
      .maybeWhen(data: (list) => list, orElse: () => <dynamic>[]);

  final results = <PersonalThreadSummary>[];

  for (final friend in friends) {
    final peerId = friend.userId;
    final displayName = ref.watch(userDisplayNameProvider(peerId));
    final thread = _findPersonalThread(threads, myId, peerId);
    final updatedAt = thread?.updatedAt ?? friend.createdAt;
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

/// グループスレッド一覧
final groupThreadsProvider = Provider<List<GroupThreadSummary>>((ref) {
  final threads = ref.watch(threadListProvider);
  final results =
      threads
          .where((t) => t.type == 'group' && t.deletedAt == null)
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

/// スレッド詳細（1対1 / グループ共通）
final threadDetailProvider = Provider.family<ThreadDetailView?, String>((
  ref,
  threadId,
) {
  final myId = ref.watch(currentUserIdProvider);
  final threads = ref.watch(threadListProvider);
  final users = ref.watch(userListProvider);

  Thread? thread = _findThreadById(threads, threadId);
  thread ??= _buildVirtualPersonalThread(users, myId, threadId);
  if (thread == null) return null;

  final isGroup = thread.type == 'group';
  final memberCount = thread.participantIds.length;
  String? peerUserId;
  String title;
  if (isGroup) {
    title = thread.title;
  } else {
    peerUserId = _resolvePeerUserId(thread.participantIds, myId);
    title = peerUserId == null
        ? thread.title
        : ref.watch(userDisplayNameProvider(peerUserId));
  }

  return ThreadDetailView(
    thread: thread,
    title: title,
    isGroup: isGroup,
    memberCount: memberCount,
    peerUserId: peerUserId,
  );
});

// ── Private helpers ───────────────────────────────────────────

Thread? _findThreadById(List<Thread> threads, String threadId) {
  for (final thread in threads) {
    if (thread.id == threadId && thread.deletedAt == null) return thread;
  }
  return null;
}

Thread? _findPersonalThread(
  List<Thread> threads,
  String myId,
  String peerUserId,
) {
  for (final thread in threads) {
    if (thread.type == 'group' || thread.deletedAt != null) continue;
    final ids = thread.participantIds;
    if (ids.contains(myId) && ids.contains(peerUserId)) {
      return thread;
    }
  }
  return null;
}

Thread? _buildVirtualPersonalThread(
  List<dynamic> users,
  String myId,
  String threadId,
) {
  if (!threadId.startsWith('virtual_personal_')) return null;
  final peerUserId = threadId.replaceFirst('virtual_personal_', '');
  // ユーザーが存在するか確認
  final exists = users.any((u) => u.id == peerUserId && u.deletedAt == null);
  if (!exists) return null;
  return Thread(
    id: threadId,
    type: 'personal',
    title: '', // 表示名はProviderで解決
    participantIds: [myId, peerUserId],
    createdAt: _fallbackDate(),
    updatedAt: _fallbackDate(),
  );
}

String _virtualThreadId(String peerUserId) => 'virtual_personal_$peerUserId';

String? _resolvePeerUserId(List<String> participantIds, String myId) {
  for (final id in participantIds) {
    if (id != myId) return id;
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
