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

  EventSummary copyWith({
    String? id,
    String? title,
    bool? isSettled,
    List<String>? members,
    DateTime? lastUpdatedAt,
    int? totalUnsettledAmount,
  }) {
    return EventSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      isSettled: isSettled ?? this.isSettled,
      members: members ?? this.members,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      totalUnsettledAmount:
          totalUnsettledAmount ?? this.totalUnsettledAmount,
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
