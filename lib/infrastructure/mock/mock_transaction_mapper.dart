import 'package:shakuyousho_app/data/mock/event_transactions_mock.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart'
    as domain_tx;

/// Mockの生データをドメインモデルに変換するためのマッパー。
/// NOTE: 本番データ（Hive/Firebase）へ移行した後は不要になる想定。
///       開発・デモ用のモックデータを使う場合のみ残す。
///
/// - DB由来のスキーマ（MockAppTransaction）と
///   アプリで使用するドメインモデル（Transaction）を分離するための層。
/// - 変換ロジックはデータ定義から切り離し、ここに集約する。

domain_tx.Transaction toDomainTransaction(MockAppTransaction tx) {
  final expense = tx.expenseDetail;
  final repayment = tx.repaymentDetail;
  return domain_tx.Transaction(
    id: tx.txId,
    eventId: tx.eventId,
    type: tx.txType == MockTransactionType.expense
        ? domain_tx.TxType.expense
        : domain_tx.TxType.repayment,
    title: tx.title,
    date: tx.date,
    currency: tx.currency,
    totalAmount: tx.totalAmount,
    participantIds: tx.participantIds,
    paidBy: expense?.paidBy,
    shares: expense?.shares,
    fromUserId: repayment?.fromUserId,
    toUserId: repayment?.toUserId,
    repaymentAmount: repayment?.amount,
    createdBy: tx.createdBy,
    createdAt: tx.createdAt,
    updatedAt: tx.updatedAt,
    deletedAt: tx.deletedAt,
  );
}

/// Mockの全取引データをドメインモデルへ一括変換。
final List<domain_tx.Transaction> mockDomainTransactions =
    List<domain_tx.Transaction>.unmodifiable(
      mockAllTransactions.map(toDomainTransaction).toList(growable: false),
    );
