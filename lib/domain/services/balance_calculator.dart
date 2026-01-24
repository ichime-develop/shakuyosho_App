import 'package:shakuyousho_app/domain/models/transaction_model.dart';

/// ユーザー視点で相手ごとの純残高を計算するサービス。
///
/// 純粋な計算ロジック。外部依存（Repository等）を持たない。
class BalanceCalculator {
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
    required List<Transaction> transactions,
    required String meUserId,
    bool includeEvents = false,
  }) {
    final net = <String, int>{};

    void add(String peer, int delta) {
      if (peer == meUserId) return;
      net[peer] = (net[peer] ?? 0) + delta;
    }

    for (final tx in transactions) {
      if (tx.deletedAt != null) continue;
      if (!includeEvents && tx.eventId != null) continue;
      if (!tx.participantIds.contains(meUserId)) continue;

      if (tx.type == TxType.expense) {
        final paidBy = tx.paidBy;
        final shares = tx.shares;
        if (paidBy == null || shares == null) continue;

        for (final entry in shares.entries) {
          final userId = entry.key;
          final share = entry.value;
          if (userId == paidBy) continue;

          if (meUserId == paidBy) {
            add(userId, share);
          } else if (meUserId == userId) {
            add(paidBy, -share);
          }
        }
      } else {
        final fromUserId = tx.fromUserId;
        final toUserId = tx.toUserId;
        final amount = tx.repaymentAmount;
        if (fromUserId == null || toUserId == null || amount == null) continue;

        if (meUserId == toUserId) {
          add(fromUserId, -amount);
        } else if (meUserId == fromUserId) {
          add(toUserId, amount);
        }
      }
    }

    return net;
  }
}
