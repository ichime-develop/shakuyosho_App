import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

/// Hive-backed implementation for Thread persistence.
class HiveThreadRepository implements ThreadRepository {
  HiveThreadRepository({required Box<Thread> threadBox})
    : _threadBox = threadBox;

  final Box<Thread> _threadBox;

  @override
  List<Thread> getAll() => _threadBox.values.toList(growable: false);

  @override
  Thread? getById(String threadId) => _threadBox.get(threadId);

  @override
  void upsert(Thread thread) {
    _threadBox.put(thread.id, thread);
  }
}
