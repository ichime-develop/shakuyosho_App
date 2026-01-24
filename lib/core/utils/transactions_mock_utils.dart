import 'package:shakuyousho_app/data/mock/transactions_mock.dart';

/// Mockデータの整合性チェック（デバッグ用）。
///
/// - `assert` を使うため、リリースビルドでは実行されない。
/// - データのみのファイルにロジックを置かないため、
///   必要な時にここから明示的に呼び出す。
bool validateMockTransactions(List<MockAppTransaction> txs) {
  for (final tx in txs) {
    if (tx.deletedAt != null) {
      // 削除済みは UI の対象外とみなす。
      continue;
    }

    // 通貨はモックでは JPY 前提（PoC 仕様）。
    assert(
      tx.currency == 'JPY',
      'Only JPY is expected in PoC mocks: ${tx.txId}',
    );

    switch (tx.txType) {
      case MockTransactionType.expense:
        final d = tx.expenseDetail;
        assert(d != null, 'expenseDetail must be set for expense: ${tx.txId}');
        if (d == null) break;

        // 1) share 合計が totalAmount と一致すること。
        final sum = d.shares.values.fold<int>(0, (p, v) => p + v);
        assert(
          sum == tx.totalAmount,
          'sum(shares) must equal totalAmount: ${tx.txId} sum=$sum total=${tx.totalAmount}',
        );

        // 2) participantIds が paidBy + shares.keys と一致すること。
        final expected = _participantsForExpense(d);
        assert(
          _sameSet(tx.participantIds, expected),
          'participantIds must match paidBy+shares.keys: ${tx.txId} expected=$expected actual=${tx.participantIds}',
        );
        break;

      case MockTransactionType.repayment:
        final d = tx.repaymentDetail;
        assert(
          d != null,
          'repaymentDetail must be set for repayment: ${tx.txId}',
        );
        if (d == null) break;

        // 1) 返済額が totalAmount と一致すること。
        assert(
          d.amount == tx.totalAmount,
          'repaymentDetail.amount must equal totalAmount: ${tx.txId} amount=${d.amount} total=${tx.totalAmount}',
        );

        // 2) participantIds が from/to と一致すること。
        final expected = _participantsForRepayment(d);
        assert(
          _sameSet(tx.participantIds, expected),
          'participantIds must match from/to: ${tx.txId} expected=$expected actual=${tx.participantIds}',
        );
        break;
    }
  }
  return true;
}

/// `meUserId` 視点で相手ごとの純残高を計算する。
///
/// ルール:
/// - 正の値: 相手が `meUserId` に返すべき（相手→me の負債）
/// - 負の値: `meUserId` が相手に返すべき（me→相手 の負債）
///
/// 計算の考え方:
/// - 支出: 支払者が各参加者の負担分を立替えたとみなす
/// - 返済: from → to の支払いで負債が減少する
Map<String, int> calcNetByPeer({
  required String meUserId,
  bool includeEvents = false,
  List<MockAppTransaction>? source,
}) {
  final txs = source ?? mockAllTransactions;
  final net = <String, int>{};

  // 相手ごとの加算ヘルパー。
  void add(String peer, int delta) {
    if (peer == meUserId) return;
    net[peer] = (net[peer] ?? 0) + delta;
  }

  for (final tx in txs) {
    if (tx.deletedAt != null) continue;
    if (!includeEvents && tx.eventId != null) continue;
    if (!tx.participantIds.contains(meUserId)) continue;

    if (tx.txType == MockTransactionType.expense) {
      final d = tx.expenseDetail;
      if (d == null) continue;

      // 支出: 各参加者の share を支払者が立替えたとみなす。
      for (final entry in d.shares.entries) {
        final userId = entry.key;
        final share = entry.value;
        if (userId == d.paidBy) continue;

        // userId → paidBy の負債として反映。
        if (meUserId == d.paidBy) {
          // 相手が自分に返すべき。
          add(userId, share);
        } else if (meUserId == userId) {
          // 自分が支払者に返すべき。
          add(d.paidBy, -share);
        }
      }
    } else {
      final d = tx.repaymentDetail;
      if (d == null) continue;

      // 返済: from → to の支払いは負債を減らす。
      if (meUserId == d.toUserId) {
        // 相手が自分に返済した。
        add(d.fromUserId, -d.amount);
      } else if (meUserId == d.fromUserId) {
        // 自分が相手に返済した。
        add(d.toUserId, d.amount);
      }
    }
  }

  return net;
}

List<String> _participantsForExpense(ExpenseDetail d) {
  final ids = <String>{d.paidBy, ...d.shares.keys};
  final list = ids.toList()..sort();
  return List<String>.unmodifiable(list);
}

List<String> _participantsForRepayment(RepaymentDetail d) {
  final ids = <String>{d.fromUserId, d.toUserId};
  final list = ids.toList()..sort();
  return List<String>.unmodifiable(list);
}

bool _sameSet(List<String> a, List<String> b) {
  final sa = a.toSet();
  final sb = b.toSet();
  return sa.length == sb.length && sa.containsAll(sb);
}
