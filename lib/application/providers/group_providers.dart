import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/usecases/create_group_usecase.dart';
import 'package:shakuyousho_app/data/mock/group_mock.dart';
import 'package:shakuyousho_app/data/repository/group_repository.dart';
import 'package:shakuyousho_app/domain/models/group_model.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return MockGroupRepository(List<Group>.from(mockGroups));
});

final createGroupUsecaseProvider = Provider<CreateGroupUsecase>((ref) {
  return CreateGroupUsecase(
    groupRepository: ref.read(groupRepositoryProvider),
    eventStateNotifier: ref.read(eventStateProvider.notifier),
    inviteService: InviteService(),
  );
});
