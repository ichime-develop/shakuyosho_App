import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

/// Hive-backed implementation for Thread persistence.
class HiveThreadRepository implements ThreadRepository {
  HiveThreadRepository({required Box<Map> threadBox})
    : _threadBox = threadBox;

  final Box<Map> _threadBox;

  @override
  List<Thread> getAll() => _threadBox.values
      .map((raw) => Thread.fromMap(_castMap(raw)))
      .where((t) => t.deletedAt == null)
      .toList(growable: false);

  @override
  Thread? getById(String threadId) {
    final raw = _threadBox.get(threadId);
    if (raw == null) return null;
    final thread = Thread.fromMap(_castMap(raw), id: threadId);
    return thread.deletedAt == null ? thread : null;
  }

  @override
  void upsert(Thread thread) {
    _threadBox.put(thread.id, thread.toMap());
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
