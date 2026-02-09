import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';

/// Mock implementation backed by lib/data/mock/event_meta_mock.dart
/// NOTE: 現在はHive実装に切替済みのため未使用。テストや比較用に保持。
class MockEventRepository implements EventRepository {
  MockEventRepository({required List<EventMeta> initialMetas})
    : _metas = List<EventMeta>.from(initialMetas);

  final List<EventMeta> _metas;

  @override
  Future<List<EventMeta>> getAllEventMetas() async =>
      List.unmodifiable(_metas);

  @override
  Future<EventMeta?> getEventMetaById(String eventId) async {
    for (final meta in _metas) {
      if (meta.id == eventId) return meta;
    }
    return null;
  }

  @override
  Future<void> upsertEventMeta(EventMeta meta) async {
    final idx = _metas.indexWhere((m) => m.id == meta.id);
    if (idx == -1) {
      _metas.add(meta);
    } else {
      _metas[idx] = meta;
    }
  }

  @override
  Future<void> deleteEventMeta(String eventId) async {
    final idx = _metas.indexWhere((m) => m.id == eventId);
    if (idx == -1) return;
    final now = DateTime.now();
    _metas[idx] = _metas[idx].copyWith(deletedAt: now, updatedAt: now);
  }
}
