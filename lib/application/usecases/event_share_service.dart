/// Pure Dart service to calculate equal shares for an event payment.
/// This file intentionally depends only on dart:core so it can be used
/// from application/business logic without Flutter imports.
class EventShareService {
  /// 均等割りで shares を計算する。
  /// totalAmount <= 0 または beneficiaryUserIds が空の場合は {} を返す。
  /// 端数は上から順に +1 して配分する（TR0100 と同じルール）。
  Map<String, int> calcEqualShares({
    required int totalAmount,
    required List<String> beneficiaryUserIds,
  }) {
    if (totalAmount <= 0 || beneficiaryUserIds.isEmpty) {
      return <String, int>{};
    }

    final count = beneficiaryUserIds.length;
    final base = totalAmount ~/ count;
    int remainder = totalAmount % count;

    final result = <String, int>{};
    for (final userId in beneficiaryUserIds) {
      var amount = base;
      if (remainder > 0) {
        amount += 1;
        remainder -= 1;
      }
      result[userId] = amount;
    }

    return result;
  }
}
