class EventSummary {
  EventSummary({
    required this.id,
    required this.title,
    required this.isSettled,
    required this.participantIds,
    required this.lastUpdatedAt,
  });

  final String id;
  final String title;
  final bool isSettled;
  // participantIds: list of userId strings
  final List<String> participantIds;
  final DateTime lastUpdatedAt;

  EventSummary copyWith({
    String? id,
    String? title,
    bool? isSettled,
    List<String>? participantIds,
    DateTime? lastUpdatedAt,
  }) {
    return EventSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      isSettled: isSettled ?? this.isSettled,
      participantIds: participantIds ?? this.participantIds,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class EventTransaction {
  EventTransaction({
    required this.id,
    required this.eventId,
    required this.title,
    required this.paidBy,
    required this.totalAmount,
    required this.shares,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String title;
  final String paidBy;
  final int totalAmount;
  final Map<String, int> shares;
  final DateTime createdAt;
}
