import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

// 取引の種別（支出 or 返済）を表す列挙型。
@HiveType(typeId: 2)
enum TxType {
  @HiveField(0)
  expense,
  @HiveField(1)
  repayment,
}

// 取引（支出/返済）の詳細を表すドメインモデル。
@HiveType(typeId: 3)
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

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? eventId; // null for personal tx
  @HiveField(2)
  final TxType type;
  @HiveField(3)
  final String title;
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String currency; // 'JPY'
  @HiveField(6)
  final int totalAmount; // integer JPY
  @HiveField(7)
  final List<String> participantIds;

  // expense-specific
  @HiveField(8)
  final String? paidBy;
  @HiveField(9)
  final Map<String, int>? shares; // userId -> amount

  // repayment-specific
  @HiveField(10)
  final String? fromUserId;
  @HiveField(11)
  final String? toUserId;
  @HiveField(12)
  final int? repaymentAmount;

  @HiveField(13)
  final String createdBy;
  @HiveField(14)
  final DateTime createdAt;
  @HiveField(15)
  final DateTime? updatedAt;
  @HiveField(16)
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
