import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/usecases/event_share_service.dart';

/// TR0100: イベント内の 1 つの支払い（取引）を入力・編集する画面
///
/// - 誰が（支払った人）
/// - 何に（タイトル/用途）
/// - いくら（合計金額）
/// - 誰の分を払ったか（参加者の中から複数選択）
///
/// という情報を入力し、均等割りで各人の負担額を簡易計算します。
/// 将来的には application/usecases 配下の Service に切り出す前提で、
/// 現時点では画面内に簡易ロジックを持たせています。
class Tr0100TransactionScreen extends ConsumerStatefulWidget {
  const Tr0100TransactionScreen({super.key});

  @override
  ConsumerState<Tr0100TransactionScreen> createState() =>
      _Tr0100TransactionScreenState();
}

class _Tr0100TransactionScreenState
    extends ConsumerState<Tr0100TransactionScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  final _eventShareService = EventShareService();

  /// 仮のイベント参加者（本来は eventId から取得）
  final List<_EventMember> _members = _mockMembers;

  String? _payerUserId; // 誰が払ったか
  final Set<String> _selectedBeneficiaryIds = {}; // 誰の分を払ったか
  Map<String, int> _shares = {}; // 各人の負担額

  @override
  void initState() {
    super.initState();
    // TODO: eventId / transactionId を使って初期値を差し込む想定
    // final eventId = Uri.base.queryParameters['eventId'];
    // final transactionId = Uri.base.queryParameters['transactionId'];

    _titleController = TextEditingController();
    _amountController = TextEditingController();

    if (_members.isNotEmpty) {
      _payerUserId = _members.first.id;
      _selectedBeneficiaryIds.addAll(_members.map((m) => m.id));
    }
    _recalcShares();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('TR0100 支払い入力'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'イベント内の 1 件分の支払いを登録します。\n'
            '誰が何にいくら払い、誰の分を払ったかをメモしておくイメージです。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),

          // 支払った人
          Text('支払った人', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _payerUserId,
            items: _members
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m.id,
                    child: Text(m.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _payerUserId = value;
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // 用途
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '何の支払いか',
              hintText: '例: 1日目 夕食, 宿代, レンタカー など',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 合計金額
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '合計金額（円）',
              hintText: '例: 6000',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _recalcShares(),
          ),
          const SizedBox(height: 16),

          // 誰の分を払ったか
          Text('誰の分を払ったか', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Column(
            children: _members
                .map(
                  (m) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.displayName),
                    value: _selectedBeneficiaryIds.contains(m.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedBeneficiaryIds.add(m.id);
                        } else {
                          _selectedBeneficiaryIds.remove(m.id);
                        }
                        _recalcShares();
                      });
                    },
                  ),
                )
                .toList(),
          ),
          if (_selectedBeneficiaryIds.isEmpty)
            Text(
              '※ 少なくとも 1 人は選択してください。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.redAccent,
              ),
            ),
          const SizedBox(height: 12),

          // 負担額の確認
          Text('各人の負担額（均等割りの簡易計算）', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _shares.isEmpty
                  ? Text(
                      '金額と対象メンバーを入力すると自動計算されます。',
                      style: theme.textTheme.bodySmall,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _members
                          .where((m) => _shares.containsKey(m.id))
                          .map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(m.displayName),
                                  Text(_fmtYen(_shares[m.id]!)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 登録ボタン
          FilledButton.icon(
            onPressed: () => _onTapSave(context),
            icon: const Icon(Icons.check),
            label: const Text('この内容で登録する'),
          ),
        ],
      ),
    );
  }

  void _recalcShares() {
    final total = int.tryParse(_amountController.text) ?? 0;
    final selected = _selectedBeneficiaryIds.toList();

    final result = _eventShareService.calcEqualShares(
      totalAmount: total,
      beneficiaryUserIds: selected,
    );

    setState(() {
      _shares = result;
    });
  }

  void _onTapSave(BuildContext context) {
    final total = int.tryParse(_amountController.text) ?? 0;
    if (_payerUserId == null || _payerUserId!.isEmpty) {
      _showError(context, '支払った人を選択してください。');
      return;
    }
    if (total <= 0) {
      _showError(context, '合計金額を入力してください。');
      return;
    }
    if (_selectedBeneficiaryIds.isEmpty) {
      _showError(context, '誰の分を払ったかを少なくとも 1 人選択してください。');
      return;
    }

    // TODO: EventTransaction モデルにマッピングして、Repository / Usecase 経由で保存する想定。
    // 現時点ではダミーで SnackBar を出して戻る。
    final snack = SnackBar(
      content: Text(
        '支払いを登録しました（ダミー）。\n'
        '支払った人: ${_members.firstWhere((m) => m.id == _payerUserId).displayName}\n'
        '合計: ${_fmtYen(total)}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
    context.pop();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

/// ---------------------------
/// モック用のイベント参加者モデル
/// ---------------------------
class _EventMember {
  final String id;
  final String displayName;

  const _EventMember({required this.id, required this.displayName});
}

const List<_EventMember> _mockMembers = [
  _EventMember(id: 'user_a', displayName: 'A さん'),
  _EventMember(id: 'user_b', displayName: 'B さん'),
  _EventMember(id: 'user_c', displayName: 'C さん'),
];

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
