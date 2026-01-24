import 'package:flutter_test/flutter_test.dart';
import 'package:shakuyousho_app/application/usecases/create_group_usecase.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

class _FakeThreadRepository implements ThreadRepository {
  final List<Thread> threads = [];

  @override
  void upsert(Thread thread) {
    final idx = threads.indexWhere((t) => t.id == thread.id);
    if (idx == -1) {
      threads.add(thread);
    } else {
      threads[idx] = thread;
    }
  }

  @override
  List<Thread> getAll() => List.unmodifiable(threads);

  @override
  Thread? getById(String threadId) {
    for (final thread in threads) {
      if (thread.id == threadId) return thread;
    }
    return null;
  }
}

class _FakeEventRepository implements EventRepository {
  final List<EventMeta> metas = [];

  @override
  List<EventMeta> getAllEventMetas() => List.unmodifiable(metas);

  @override
  EventMeta? getEventMetaById(String id) {
    for (final meta in metas) {
      if (meta.id == id) return meta;
    }
    return null;
  }

  @override
  void upsertEventMeta(EventMeta meta) {
    final idx = metas.indexWhere((m) => m.id == meta.id);
    if (idx == -1) {
      metas.add(meta);
    } else {
      metas[idx] = meta;
    }
  }

  @override
  void deleteEventMeta(String id) {
    metas.removeWhere((m) => m.id == id);
  }
}

class _FakeInviteService extends InviteService {
  final List<Map<String, String?>> sent = [];

  @override
  Future<void> sendInvite({
    required String groupId,
    required String memberId,
    String? message,
  }) async {
    sent.add({'groupId': groupId, 'memberId': memberId, 'message': message});
  }
}

void main() {
  test('CreateGroupUsecase creates group, event, and sends invites', () async {
    final threadRepo = _FakeThreadRepository();
    final eventRepo = _FakeEventRepository();
    final inviteService = _FakeInviteService();
    final now = DateTime(2025, 1, 2, 3, 4);

    final usecase = CreateGroupUsecase(
      threadRepository: threadRepo,
      eventRepository: eventRepo,
      inviteService: inviteService,
      now: () => now,
      randomInt: (max) => 7,
    );

    final result = await usecase.execute(
      CreateGroupRequest(
        title: 'Trip',
        memberIds: ['u_002'],
        createdBy: 'u_001',
      ),
    );

    expect(result.thread.id, 'th_Trip_202501020304007');
    expect(result.eventMeta.id, 'ev_Trip_202501020304007');
    expect(result.thread.participantIds.toSet(), {'u_001', 'u_002'});
    expect(eventRepo.getAllEventMetas().length, 1);
    expect(inviteService.sent.length, 1);
    expect(inviteService.sent.first['memberId'], 'u_002');
  });
}
