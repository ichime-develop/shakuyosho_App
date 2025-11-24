import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Fr0200FriendDetailScreen extends ConsumerWidget {
  const Fr0200FriendDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = Uri.base.queryParameters['friendId'] ?? '';
    final friend = _mockFriends[friendId] ?? _mockFriends.values.first;
    final transactions = _mockTransactions
        .where((t) => t.friendId == friend.id)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final net = _calcNetBalance(transactions);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('${friend.displayName} とのやりとり (FR0200)'),
      ),
      body: Column(
        children: [
          // ヘッダー：サマリ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text(friend.displayName.substring(0, 1))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.displayName,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _netText(net),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: net > 0
                                  ? Colors.teal
                                  : net < 0
                                      ? Colors.deepOrange
                                      : theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '直近: ${transactions.isEmpty ? '取引なし' : _fmtDateTime(transactions.last.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // チャットタイムライン
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text('この友だちとのお金のやりとりはまだありません。'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isMe = tx.direction == _Direction.fromMe;
                      final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
                      final crossAlign =
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                      final bubbleColor = isMe
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant;
                      final textColor = theme.colorScheme.onSurface;

                      return Align(
                        alignment: align,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: crossAlign,
                            children: [
                              Text(
                                _fmtDateTime(tx.createdAt),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: theme.hintColor),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: tx.status == _TransactionStatus.pending
                                    ? () => _Controller.onTapTransaction(
                                          context,
                                          friend.id,
                                          tx,
                                        )
                                    : null,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: crossAlign,
                                    children: [
                                      Text(
                                        _fmtYen(tx.amount),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      if (tx.label.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tx.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: textColor),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _statusText(tx.status),
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: _statusColor(tx.status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (tx.status == _TransactionStatus.pending)
                                            Text(
                                              '  タップで借用書を作成',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // いったん下部入力はモック（将来ここから請求/追加）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: '支払いの追加やメモは今後ここから（モック）',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('支払い追加機能は未実装です（モック）')),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Controller（LB0100 への遷移など）
/// ---------------------------
class _Controller {
  static void onTapTransaction(
    BuildContext context,
    String friendId,
    _FriendTransaction tx,
  ) {
    final uri = Uri(
      path: '/lb0100',
      queryParameters: <String, String>{
        'mode': 'personal',
        'friendId': friendId,
        'transactionId': tx.id,
      },
    );
    context.push(uri.toString());
  }
}

/// ---------------------------
/// モデル & モックデータ
/// ---------------------------
class _Friend {
  final String id;
  final String displayName;
  const _Friend({required this.id, required this.displayName});
}

enum _Direction { fromMe, toMe }

enum _TransactionStatus { pending, iouIssued, settled }

class _FriendTransaction {
  final String id;
  final String friendId;
  final _Direction direction; // fromMe: 自分が立替 or 請求 / toMe: 相手から
  final int amount;
  final String label;
  final DateTime createdAt;
  final _TransactionStatus status;

  const _FriendTransaction({
    required this.id,
    required this.friendId,
    required this.direction,
    required this.amount,
    required this.label,
    required this.createdAt,
    required this.status,
  });
}

final Map<String, _Friend> _mockFriends = {
  'f_sakaguchi': const _Friend(id: 'f_sakaguchi', displayName: 'さかぐち'),
  'f_ayaka': const _Friend(id: 'f_ayaka', displayName: 'あやか'),
};

final List<_FriendTransaction> _mockTransactions = [
  _FriendTransaction(
    id: 'tx_001',
    friendId: 'f_sakaguchi',
    direction: _Direction.fromMe,
    amount: 3200,
    label: '飲み会 割り勘',
    createdAt: DateTime(2024, 5, 3, 19, 30),
    status: _TransactionStatus.pending,
  ),
  _FriendTransaction(
    id: 'tx_002',
    friendId: 'f_sakaguchi',
    direction: _Direction.toMe,
    amount: 1200,
    label: 'タクシー代 立替',
    createdAt: DateTime(2024, 5, 4, 0, 15),
    status: _TransactionStatus.iouIssued,
  ),
  _FriendTransaction(
    id: 'tx_003',
    friendId: 'f_ayaka',
    direction: _Direction.toMe,
    amount: 5000,
    label: 'ライブチケット',
    createdAt: DateTime(2024, 6, 10, 18, 0),
    status: _TransactionStatus.settled,
  ),
];

int _calcNetBalance(List<_FriendTransaction> list) {
  // fromMe: 自分が多く払っている → 相手から受け取りたい(＋)
  // toMe: 相手が多く払っている → 自分が支払う必要がある(−)
  int net = 0;
  for (final tx in list) {
    if (tx.direction == _Direction.fromMe) {
      net += tx.amount;
    } else if (tx.direction == _Direction.toMe) {
      net -= tx.amount;
    }
  }
  return net;
}

String _netText(int net) {
  if (net > 0) {
    return 'あなたが ${_fmtYen(net)} 貸しています';
  } else if (net < 0) {
    return 'あなたが ${_fmtYen(-net)} 借りています';
  } else {
    return '貸し借りはありません';
  }
}

String _fmtYen(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final r = s.length - i;
    buf.write(s[i]);
    if (r > 1 && r % 3 == 1) buf.write(',');
  }
  return '¥${buf.toString()}';
}

String _fmtDateTime(DateTime d) {
  final date =
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String _statusText(_TransactionStatus s) {
  switch (s) {
    case _TransactionStatus.pending:
      return '未精算';
    case _TransactionStatus.iouIssued:
      return '借用書発行済み';
    case _TransactionStatus.settled:
      return '精算済み';
  }
}

Color _statusColor(_TransactionStatus s) {
  switch (s) {
    case _TransactionStatus.pending:
      return Colors.deepOrange;
    case _TransactionStatus.iouIssued:
      return Colors.indigo;
    case _TransactionStatus.settled:
      return Colors.green;
  }
}
