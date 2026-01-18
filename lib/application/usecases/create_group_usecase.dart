import 'dart:math';

import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/repository/group_repository.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/group_model.dart';

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
  CreateGroupResult({required this.group, required this.eventMeta});

  final Group group;
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
    required GroupRepository groupRepository,
    required EventStateNotifier eventStateNotifier,
    required InviteService inviteService,
    DateTime Function()? now,
    int Function(int max)? randomInt,
  })  : _groupRepository = groupRepository,
        _eventStateNotifier = eventStateNotifier,
        _inviteService = inviteService,
        _now = now ?? DateTime.now,
        _randomInt = randomInt ?? ((max) => Random().nextInt(max));

  final GroupRepository _groupRepository;
  final EventStateNotifier _eventStateNotifier;
  final InviteService _inviteService;
  final DateTime Function() _now;
  final int Function(int max) _randomInt;

  Future<CreateGroupResult> execute(CreateGroupRequest input) async {
    final createdAt = _now();
    final token = _buildToken(input.title, createdAt);
    final memberIds = _mergeMembers(input.memberIds, input.createdBy);
    final group = Group(
      id: 'grp_$token',
      title: input.title,
      memberIds: memberIds,
      createdBy: input.createdBy,
      createdAt: createdAt,
    );

    _groupRepository.create(group);

    for (final memberId in memberIds) {
      if (memberId == input.createdBy) continue;
      await _inviteService.sendInvite(
        groupId: group.id,
        memberId: memberId,
        message: input.inviteMessage,
      );
    }

    final eventId = await _eventStateNotifier.createEventMeta(
      title: '${group.title} のイベント',
      participantIds: List<String>.unmodifiable(memberIds),
    );
    final eventMeta = _eventStateNotifier.state.metas.firstWhere(
      (meta) => meta.id == eventId,
    );

    return CreateGroupResult(group: group, eventMeta: eventMeta);
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
