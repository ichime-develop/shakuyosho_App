import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';

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
