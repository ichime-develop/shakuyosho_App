import 'package:shakuyousho_app/domain/models/event_models.dart';

import 'events_mock.dart' as events_source;

final List<EventSummary> mockEvents =
    List.unmodifiable(events_source.mockEvents);

final List<EventTransaction> mockTransactions =
    List.unmodifiable(events_source.mockTransactions);

final Map<String, List<String>> mockEventMemberUserIds =
    Map.unmodifiable(events_source.mockEventMemberUserIds);
