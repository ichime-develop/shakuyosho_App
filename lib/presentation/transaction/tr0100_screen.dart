import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/usecases/event_share_service.dart';

/// TR0100: イベント内の 1 つの支払い（取引）を入力・編集する画面
///
/// スクショ「岡山ホテル」画面のイメージに合わせて、以下を入力できる:
/// - イベント名（取引名）: テキスト入力
/// - 支払い情報: 合計金額（円）
/// - 支払った人: イベント参加メンバーから 1 人選択
/// - 内訳設定ゾーン:
///    - チェックボックス: この人を割り勘対象に含めるか
///    - 名前
///    - 個別金額フィールド: 1 人あたりの負担額を編集可能
///
/// 合計金額を変更したときや割り勘対象の人を変更したときに、
/// application/usecases/event_share_service.dart の EventShareService を使って
/// 均等割り額を自動で振り分ける簡易ロジックを入れている。
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

  /// 誰が払ったか
  String? _payerUserId;

  /// 内訳設定ゾーンを表示するかどうか
  bool _showBreakdown = true;

  /// 各メンバーの割り勘設定（チェック状態＋個別金額）
  late List<_MemberShareState> _memberShares;

  @override
  void initState() {
    super.initState();

    // TODO: eventId / transactionId を使って初期値を差し込む想定
    // final eventId = Uri.base.queryParameters['eventId'];
    // final transactionId = Uri.base.queryParameters['transactionId'];

    _titleController = TextEditingController();
    _amountController = TextEditingController();

    // デフォルトでは全員を割り勘対象にしておく
    _memberShares = _members
        .map(
          (m) => _MemberShareState(
            memberId: m.id,
            name: m.displayName,
            included: true,
            controller: TextEditingController(),
          ),
        )
        .toList();

    if (_members.isNotEmpty) {
      _payerUserId = _members.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final s in _memberShares) {
      s.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('TR0100 おしはらいメモ'),
        actions: [TextButton(onPressed: _onTapSave, child: const Text('ほぞん'))],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // イベント名（取引名）
                Text('イベントのなまえ（とりひき）', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'イベントのなまえ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 支払い情報（合計金額）
                Text('おしはらいのないよう', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '¥',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'きんがく',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalcShares(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 支払った人ピッカー
                Text('はらったひと', style: theme.textTheme.labelLarge),
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

                // 内訳設定の開閉ボタン
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showBreakdown = !_showBreakdown;
                      });
                    },
                    icon: Icon(
                      _showBreakdown ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(_showBreakdown ? 'ないようをとじる' : 'ないようをひらく'),
                  ),
                ),
                const SizedBox(height: 8),

                if (_showBreakdown) ...[
                  Row(
                    children: [
                      Text('ないようのわりふり', style: theme.textTheme.labelLarge),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'チェックしたひとでわりかんするかんじだよ。',
                        child: const Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBreakdownCard(theme),
                ],

                const SizedBox(height: 24),

                // 保存ボタン（AppBar の保存と同じ挙動にしておく）
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onTapSave,
                    child: const Text('ほぞん'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 内訳ゾーンのカード
  Widget _buildBreakdownCard(ThemeData theme) {
    return Card(
      child: Column(
        children: _memberShares.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: s.included,
                  onChanged: (v) {
                    setState(() {
                      s.included = v ?? false;
                      _recalcShares();
                    });
                  },
                ),
                Expanded(
                  child: Text(s.name, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: s.controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 合計金額や割り勘対象が変わったときに均等割りを再計算し、
  /// 各メンバーの TextField に反映する。
  void _recalcShares() {
    final total = int.tryParse(_amountController.text) ?? 0;
    final targetIds = _memberShares
        .where((s) => s.included)
        .map((s) => s.memberId)
        .toList();

    if (total <= 0 || targetIds.isEmpty) {
      // 金額または対象がない場合はクリアだけする
      setState(() {
        for (final s in _memberShares) {
          if (s.included) {
            s.controller.text = '';
          }
        }
      });
      return;
    }

    final result = _eventShareService.calcEqualShares(
      totalAmount: total,
      beneficiaryUserIds: targetIds,
    );

    setState(() {
      for (final s in _memberShares) {
        if (result.containsKey(s.memberId)) {
          s.controller.text = result[s.memberId]!.toString();
        } else if (s.included) {
          s.controller.text = '';
        }
      }
    });
  }

  void _onTapSave() {
    final context = this.context;
    final total = int.tryParse(_amountController.text) ?? 0;

    if (_payerUserId == null || _payerUserId!.isEmpty) {
      _showError(context, 'はらったひとをえらんでね。');
      return;
    }
    if (total <= 0) {
      _showError(context, 'ごうけいきんがくをいれてね。');
      return;
    }
    final included = _memberShares.where((s) => s.included).toList();
    if (included.isEmpty) {
      _showError(context, 'すくなくともひとりはわりかんメンバーにしてね。');
      return;
    }

    // TODO: EventTransaction モデルにマッピングして Repository / Usecase 経由で保存する想定。
    // 現時点ではダミーで SnackBar を出して戻る。
    final payerName = _members
        .firstWhere((m) => m.id == _payerUserId)
        .displayName;
    final snack = SnackBar(
      content: Text(
        'おしはらいをのこしました（ダミー）。\n'
        'はらったひと: $payerName\n'
        'ごうけい: ${_fmtYen(total)}',
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
/// 画面内だけで使うメンバー／内訳状態
/// ---------------------------
class _EventMember {
  final String id;
  final String displayName;

  const _EventMember({required this.id, required this.displayName});
}

class _MemberShareState {
  _MemberShareState({
    required this.memberId,
    required this.name,
    required this.included,
    required this.controller,
  });

  final String memberId;
  final String name;
  bool included;
  final TextEditingController controller;
}

/// 仮メンバー（本来は eventId から取得）
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
