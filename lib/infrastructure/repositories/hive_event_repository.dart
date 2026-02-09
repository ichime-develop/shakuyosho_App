import 'package:hive/hive.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';

/// Hive-backed implementation for EventMeta persistence.
class HiveEventRepository implements EventRepository {
  HiveEventRepository({required Box<Map> eventMetaBox})
    : _eventMetaBox = eventMetaBox;

  final Box<Map> _eventMetaBox;

  @override
  Future<List<EventMeta>> getAllEventMetas() async {
    return _eventMetaBox.values
        .map((raw) => EventMeta.fromMap(_castMap(raw)))
        .toList(growable: false);
  }

  @override
  Future<EventMeta?> getEventMetaById(String eventId) async {
    final raw = _eventMetaBox.get(eventId);
    if (raw == null) return null;
    return EventMeta.fromMap(_castMap(raw), id: eventId);
  }

  @override
  Future<void> upsertEventMeta(EventMeta meta) async {
    _eventMetaBox.put(meta.id, meta.toMap());
  }

  @override
  Future<void> deleteEventMeta(String eventId) async {
    final raw = _eventMetaBox.get(eventId);
    if (raw == null) return;
    final current = EventMeta.fromMap(_castMap(raw), id: eventId);
    final now = DateTime.now();
    final updated = current.copyWith(deletedAt: now, updatedAt: now);
    _eventMetaBox.put(eventId, updated.toMap());
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}
