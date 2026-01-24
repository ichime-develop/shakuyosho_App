import 'package:shakuyousho_app/domain/models/group_model.dart';
import 'package:shakuyousho_app/domain/repositories/group_repository.dart';

class MockGroupRepository implements GroupRepository {
  MockGroupRepository(List<Group> initial)
    : _groups = List<Group>.from(initial);

  final List<Group> _groups;

  @override
  List<Group> getAllGroups() => List.unmodifiable(_groups);

  @override
  Group? getGroupById(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  @override
  void create(Group group) {
    _groups.add(group);
  }
}
