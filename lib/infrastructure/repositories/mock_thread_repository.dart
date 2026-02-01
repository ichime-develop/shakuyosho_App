import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

/// NOTE: 現在はHive実装に切替済みのため未使用。テストや比較用に保持。
class MockThreadRepository implements ThreadRepository {
  MockThreadRepository(List<Thread> initial)
    : _threads = List<Thread>.from(initial);

  final List<Thread> _threads;

  @override
  List<Thread> getAll() => List.unmodifiable(_threads);

  @override
  Thread? getById(String threadId) {
    for (final thread in _threads) {
      if (thread.id == threadId) return thread;
    }
    return null;
  }

  @override
  void upsert(Thread thread) {
    final idx = _threads.indexWhere((t) => t.id == thread.id);
    if (idx == -1) {
      _threads.add(thread);
    } else {
      _threads[idx] = thread;
    }
  }
}
