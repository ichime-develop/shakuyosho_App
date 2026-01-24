import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';

/// Mock implementation backed by lib/data/mock/event_meta_mock.dart
class MockEventRepository implements EventRepository {
  MockEventRepository({required List<EventMeta> initialMetas})
    : _metas = List<EventMeta>.from(initialMetas);

  final List<EventMeta> _metas;

  @override
  List<EventMeta> getAllEventMetas() => List.unmodifiable(_metas);

  @override
  EventMeta? getEventMetaById(String eventId) {
    for (final meta in _metas) {
      if (meta.id == eventId) return meta;
    }
    return null;
  }

  @override
  void upsertEventMeta(EventMeta meta) {
    final idx = _metas.indexWhere((m) => m.id == meta.id);
    if (idx == -1) {
      _metas.add(meta);
    } else {
      _metas[idx] = meta;
    }
  }

  @override
  void deleteEventMeta(String eventId) {
    _metas.removeWhere((m) => m.id == eventId);
  }
}
