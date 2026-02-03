// 取引の種別（支出 or 返済）を表す列挙型。
enum TxType {
  expense,
  repayment,
}

// 取引（支出/返済）の詳細を表すドメインモデル。
class Transaction {
  Transaction({
    required this.id,
    this.eventId,
    required this.type,
    required this.title,
    required this.date,
    required this.currency,
    required this.totalAmount,
    required this.participantIds,
    this.paidBy,
    this.shares,
    this.fromUserId,
    this.toUserId,
    this.repaymentAmount,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? eventId; // null for personal tx
  final TxType type;
  final String title;
  final DateTime date;
  final String currency; // 'JPY'
  final int totalAmount; // integer JPY
  final List<String> participantIds;

  // expense-specific
  final String? paidBy;
  final Map<String, int>? shares; // userId -> amount

  // repayment-specific
  final String? fromUserId;
  final String? toUserId;
  final int? repaymentAmount;

  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Transaction copyWith({
    String? id,
    String? eventId,
    TxType? type,
    String? title,
    DateTime? date,
    String? currency,
    int? totalAmount,
    List<String>? participantIds,
    String? paidBy,
    Map<String, int>? shares,
    String? fromUserId,
    String? toUserId,
    int? repaymentAmount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      totalAmount: totalAmount ?? this.totalAmount,
      participantIds: participantIds ?? this.participantIds,
      paidBy: paidBy ?? this.paidBy,
      shares: shares ?? this.shares,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      repaymentAmount: repaymentAmount ?? this.repaymentAmount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'type': type.name,
      'title': title,
      'dateMs': date.millisecondsSinceEpoch,
      'currency': currency,
      'totalAmount': totalAmount,
      'participantIds': participantIds,
      'paidBy': paidBy,
      'shares': shares,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'repaymentAmount': repaymentAmount,
      'createdBy': createdBy,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt?.millisecondsSinceEpoch,
      'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    final typeRaw = map['type'];
    final type = _txTypeFrom(typeRaw);
    return Transaction(
      id: resolvedId,
      eventId: map['eventId'] as String?,
      type: type,
      title: map['title'] as String? ?? '',
      date: _dateFrom(map['dateMs'] ?? map['date']),
      currency: map['currency'] as String? ?? 'JPY',
      totalAmount: _intFrom(map['totalAmount']),
      participantIds: _stringListFrom(map['participantIds']),
      paidBy: map['paidBy'] as String?,
      shares: _stringIntMapFrom(map['shares']),
      fromUserId: map['fromUserId'] as String?,
      toUserId: map['toUserId'] as String?,
      repaymentAmount: _intFromNullable(map['repaymentAmount']),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _dateFrom(map['createdAtMs'] ?? map['createdAt']),
      updatedAt: _dateFromNullable(map['updatedAtMs'] ?? map['updatedAt']),
      deletedAt: _dateFromNullable(map['deletedAtMs'] ?? map['deletedAt']),
    );
  }
}

// 精算時の支払指示（誰が誰にいくら払うか）を表すモデル。
class SettlementInstruction {
  SettlementInstruction({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
  });

  final String fromUserId;
  final String toUserId;
  final int amount;
  final String currency;
}

// 精算の集計結果（残高と支払指示の一覧）を表すモデル。
class SettlementSummary {
  SettlementSummary({
    required this.eventId,
    required this.balancesByUserId,
    required this.instructions,
    required this.generatedAt,
  });

  final String eventId;
  final Map<String, int> balancesByUserId;
  final List<SettlementInstruction> instructions;
  final DateTime generatedAt;
}

TxType _txTypeFrom(dynamic raw) {
  if (raw is TxType) return raw;
  if (raw is String) {
    for (final v in TxType.values) {
      if (v.name == raw) return v;
    }
  }
  if (raw is int && raw >= 0 && raw < TxType.values.length) {
    return TxType.values[raw];
  }
  return TxType.expense;
}

int _intFrom(dynamic raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

int? _intFromNullable(dynamic raw) {
  if (raw == null) return null;
  return _intFrom(raw);
}

DateTime _dateFrom(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _dateFromNullable(dynamic raw) {
  if (raw == null) return null;
  return _dateFrom(raw);
}

List<String> _stringListFrom(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => '$e').toList(growable: false);
  }
  return const <String>[];
}

Map<String, int>? _stringIntMapFrom(dynamic raw) {
  if (raw is Map) {
    final result = <String, int>{};
    raw.forEach((key, value) {
      result['$key'] = _intFrom(value);
    });
    return result;
  }
  return null;
}
