import '../models/loan_model.dart';

/// Loan（借用書）リポジトリのインターフェース
abstract class LoanRepository {
  /// 全件取得
  Future<List<Loan>> getAll();

  /// IDで1件取得
  Future<Loan?> getById(String id);

  /// 相手ユーザーIDで絞り込み
  Future<List<Loan>> getByCounterparty(String counterpartyId);

  /// 保存（新規・更新）
  Future<void> upsert(Loan loan);

  /// 削除
  Future<void> delete(String id);

  /// 貸借合計（残額ベース）を計算
  /// 戻り値: (かした残額, かりた残額)
  Future<({int lentTotal, int borrowedTotal})> calcTotals();

  /// 新規ID生成
  String newId();
}
