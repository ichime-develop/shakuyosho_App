import 'dart:math';

import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

class CreateGroupRequest {
  CreateGroupRequest({
    required this.title,
    required this.memberIds,
    required this.createdBy,
    this.inviteMessage,
  });

  final String title;
  final List<String> memberIds;
  final String createdBy;
  final String? inviteMessage;
}

class CreateGroupResult {
  CreateGroupResult({required this.thread, required this.eventMeta});

  final Thread thread;
  final EventMeta eventMeta;
}

class InviteService {
  Future<void> sendInvite({
    required String groupId,
    required String memberId,
    String? message,
  }) async {
    // Mock: no-op
  }
}

class CreateGroupUsecase {
  CreateGroupUsecase({
    required ThreadRepository threadRepository,
    required EventRepository eventRepository,
    required InviteService inviteService,
    DateTime Function()? now,
    int Function(int max)? randomInt,
  }) : _threadRepository = threadRepository,
       _eventRepository = eventRepository,
       _inviteService = inviteService,
       _now = now ?? DateTime.now,
       _randomInt = randomInt ?? ((max) => Random().nextInt(max));

  final ThreadRepository _threadRepository;
  final EventRepository _eventRepository;
  final InviteService _inviteService;
  final DateTime Function() _now;
  final int Function(int max) _randomInt;

  Future<CreateGroupResult> execute(CreateGroupRequest input) async {
    final createdAt = _now();
    final token = _buildToken(input.title, createdAt);
    final memberIds = _mergeMembers(input.memberIds, input.createdBy);
    final thread = Thread(
      id: 'th_$token',
      type: 'group',
      title: input.title,
      participantIds: memberIds,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    _threadRepository.upsert(thread);

    for (final memberId in memberIds) {
      if (memberId == input.createdBy) continue;
      await _inviteService.sendInvite(
        groupId: thread.id,
        memberId: memberId,
        message: input.inviteMessage,
      );
    }

    final eventMeta = EventMeta(
      id: 'ev_$token',
      title: input.title,
      participantIds: List<String>.unmodifiable(memberIds),
      createdAt: createdAt,
      updatedAt: createdAt,
      status: EventStatus.inProgress,
      deletedAt: null,
    );
    await _eventRepository.upsertEventMeta(eventMeta);

    return CreateGroupResult(thread: thread, eventMeta: eventMeta);
  }

  List<String> _mergeMembers(List<String> members, String createdBy) {
    final set = <String>{...members, createdBy};
    return set.toList(growable: false);
  }

  String _buildToken(String title, DateTime now) {
    final safeTitle = title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final prefix = safeTitle.isEmpty ? 'group' : safeTitle;
    final date =
        '${now.year}${_two(now.month)}${_two(now.day)}${_two(now.hour)}${_two(now.minute)}';
    final rand = _randomInt(1000).toString().padLeft(3, '0');
    return '${prefix}_$date$rand';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
