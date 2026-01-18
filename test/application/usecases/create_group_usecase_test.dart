import 'package:flutter_test/flutter_test.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/usecases/create_group_usecase.dart';
import 'package:shakuyousho_app/data/repository/event_repository.dart';
import 'package:shakuyousho_app/data/repository/group_repository.dart';
import 'package:shakuyousho_app/data/repository/transaction_repository.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/domain/models/group_model.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

class _FakeGroupRepository implements GroupRepository {
  final List<Group> groups = [];

  @override
  void create(Group group) {
    groups.add(group);
  }

  @override
  List<Group> getAllGroups() => List.unmodifiable(groups);

  @override
  Group? getGroupById(String id) {
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }
}

class _FakeEventRepository implements EventRepository {
  final List<EventSummary> events = [];
  final List<EventMeta> metas = [];

  @override
  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
  }

  @override
  List<EventSummary> getAllEvents() => List.unmodifiable(events);

  @override
  EventSummary? getEventById(String id) {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  void upsertEvent(EventSummary event) {
    final idx = events.indexWhere((e) => e.id == event.id);
    if (idx == -1) {
      events.add(event);
    } else {
      events[idx] = event;
    }
  }

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

class _FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> txs = [];

  @override
  void deleteTransaction(String txId) {
    txs.removeWhere((t) => t.id == txId);
  }

  @override
  List<Transaction> getAllTransactions() => List.unmodifiable(txs);

  @override
  List<Transaction> getTransactionsByEvent(String eventId) =>
      txs.where((t) => t.eventId == eventId).toList(growable: false);

  @override
  void upsertTransaction(Transaction tx) {
    final idx = txs.indexWhere((t) => t.id == tx.id);
    if (idx == -1) {
      txs.add(tx);
    } else {
      txs[idx] = tx;
    }
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
    final groupRepo = _FakeGroupRepository();
    final eventRepo = _FakeEventRepository();
    final txRepo = _FakeTransactionRepository();
    final eventNotifier = EventStateNotifier(
      eventRepository: eventRepo,
      transactionRepository: txRepo,
      eventIdGenerator: () => 'ev_test_001',
    );
    final inviteService = _FakeInviteService();
    final now = DateTime(2025, 1, 2, 3, 4);

    final usecase = CreateGroupUsecase(
      groupRepository: groupRepo,
      eventStateNotifier: eventNotifier,
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

    expect(result.group.id, 'grp_Trip_202501020304007');
    expect(result.eventMeta.id, 'ev_test_001');
    expect(result.group.memberIds.toSet(), {'u_001', 'u_002'});
    expect(eventRepo.getAllEventMetas().length, 1);
    expect(eventNotifier.state.metas.length, 1);
    expect(inviteService.sent.length, 1);
    expect(inviteService.sent.first['memberId'], 'u_002');
  });
}
