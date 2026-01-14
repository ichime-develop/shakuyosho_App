import 'package:shakuyousho_app/domain/models/event_models.dart';

abstract class EventRepository {
  List<EventSummary> getAllEvents();
  EventSummary? getEventById(String id);
  void upsertEvent(EventSummary event);
  void deleteEvent(String id);
}

/// Mock implementation backed by lib/data/mock/event_mock.dart
class MockEventRepository implements EventRepository {
  MockEventRepository(List<EventSummary> initial)
    : _events = List<EventSummary>.from(initial);

  final List<EventSummary> _events;

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
}
