import 'package:shakuyousho_app/data/mock/event_transactions_mock.dart';

/// Mockデータの整合性チェック（デバッグ用）。
///
/// - `assert` を使うため、リリースビルドでは実行されない。
/// - Mock実装専用のバリデーター。
/// NOTE: 本番データ（Hive/Firebase）へ移行した後は不要になる想定。
///       開発・デモ用のモックデータを使う場合のみ残す。
bool validateMockTransactions(List<MockAppTransaction> txs) {
  for (final tx in txs) {
    if (tx.deletedAt != null) {
      continue;
    }

    assert(
      tx.currency == 'JPY',
      'Only JPY is expected in PoC mocks: ${tx.txId}',
    );

    switch (tx.txType) {
      case MockTransactionType.expense:
        final d = tx.expenseDetail;
        assert(d != null, 'expenseDetail must be set for expense: ${tx.txId}');
        if (d == null) break;

        final sum = d.shares.values.fold<int>(0, (p, v) => p + v);
        assert(
          sum == tx.totalAmount,
          'sum(shares) must equal totalAmount: ${tx.txId} sum=$sum total=${tx.totalAmount}',
        );

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

        assert(
          d.amount == tx.totalAmount,
          'repaymentDetail.amount must equal totalAmount: ${tx.txId} amount=${d.amount} total=${tx.totalAmount}',
        );

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
