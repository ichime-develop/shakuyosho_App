class EventSummary {
  EventSummary({
    required this.id,
    required this.title,
    required this.isSettled,
    required this.members,
    required this.lastUpdatedAt,
    required this.totalUnsettledAmount,
  });

  final String id;
  final String title;
  final bool isSettled;
  final List<String> members;
  final DateTime lastUpdatedAt;
  final int totalUnsettledAmount;
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
