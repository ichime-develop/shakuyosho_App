import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';

/// Hive-backed implementation for EventMeta persistence.
class HiveEventRepository implements EventRepository {
  HiveEventRepository({required Box<EventMeta> eventMetaBox})
    : _eventMetaBox = eventMetaBox;

  final Box<EventMeta> _eventMetaBox;

  @override
  List<EventMeta> getAllEventMetas() {
    return _eventMetaBox.values.toList(growable: false);
  }

  @override
  EventMeta? getEventMetaById(String eventId) {
    return _eventMetaBox.get(eventId);
  }

  @override
  void upsertEventMeta(EventMeta meta) {
    _eventMetaBox.put(meta.id, meta);
  }

  @override
  void deleteEventMeta(String eventId) {
    _eventMetaBox.delete(eventId);
  }
}
