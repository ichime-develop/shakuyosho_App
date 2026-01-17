import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';

abstract class EventRepository {
  List<EventSummary> getAllEvents();
  EventSummary? getEventById(String id);

  /// Legacy API: read-only for backward compatibility.
  void upsertEvent(EventSummary event);

  /// Legacy API: read-only for backward compatibility.
  void deleteEvent(String id);

  // EventMeta API (primary source of truth)
  List<EventMeta> getAllEventMetas();
  EventMeta? getEventMetaById(String id);
  void upsertEventMeta(EventMeta meta);
  void deleteEventMeta(String id);
}

/// Mock implementation backed by lib/data/mock/event_mock.dart
class MockEventRepository implements EventRepository {
  MockEventRepository({
    required List<EventSummary> initialEvents,
    required List<EventMeta> initialMetas,
  })  : _events = List<EventSummary>.from(initialEvents),
        _metas = List<EventMeta>.from(initialMetas);

  final List<EventSummary> _events;
  final List<EventMeta> _metas;

  @override
  List<EventSummary> getAllEvents() => List.unmodifiable(_events);

  @override
  EventSummary? getEventById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  void upsertEvent(EventSummary event) {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx == -1) {
      _events.add(event);
    } else {
      _events[idx] = event;
    }
  }

  @override
  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
  }

  @override
  List<EventMeta> getAllEventMetas() => List.unmodifiable(_metas);

  @override
  EventMeta? getEventMetaById(String id) {
    for (final meta in _metas) {
      if (meta.id == id) return meta;
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
  void deleteEventMeta(String id) {
    _metas.removeWhere((m) => m.id == id);
  }
}
