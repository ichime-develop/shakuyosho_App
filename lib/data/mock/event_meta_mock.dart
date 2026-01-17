import 'package:shakuyousho_app/data/mock/event_mock.dart' as event_mock;
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';

final List<EventMeta> mockEventMetas = List.unmodifiable(
  event_mock.mockEvents.map((summary) {
    return EventMeta(
      id: summary.id,
      title: summary.title,
      participantIds: List<String>.from(summary.participantIds),
      createdAt: summary.lastUpdatedAt,
      updatedAt: summary.lastUpdatedAt,
      deletedAt: null,
    );
  }).toList(growable: false),
);
