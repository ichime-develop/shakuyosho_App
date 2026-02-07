import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';

final currentUserProvider = Provider<User?>((ref) {
  final users = ref.watch(userListProvider);
  for (final user in users) {
    if (user.id == currentUserId && user.deletedAt == null) {
      return user;
    }
  }
  return null;
});
