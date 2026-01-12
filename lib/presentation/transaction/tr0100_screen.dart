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
  bool _showBreakdown = false;
  bool _payerExpanded = false;

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'なんのおかね？'),
                const SizedBox(height: 8),
                _SoftInputCard(
                  child: Row(
                    children: [
                      const _IconBadge(icon: Icons.edit_note),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'れい：ランチ、タクシー…',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel(text: 'いくら？'),
                const SizedBox(height: 8),
                _SoftInputCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '¥',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _recalcShares(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _AccordionCard(
                  icon: Icons.payments,
                  title: 'だれがはらった？',
                  summary: _payerUserId == null
                      ? 'えらんでね'
                      : _members
                          .firstWhere((m) => m.id == _payerUserId)
                          .displayName,
                  expanded: _payerExpanded,
                  onToggle: (value) {
                    setState(() => _payerExpanded = value);
                  },
                  child: Column(
                    children: _members.map((m) {
                      return RadioListTile<String>(
                        value: m.id,
                        groupValue: _payerUserId,
                        onChanged: (value) {
                          setState(() => _payerUserId = value);
                        },
                        title: Text(
                          m.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _AccordionCard(
                  icon: Icons.call_split,
                  title: 'わりかんのせってい',
                  summary: _memberShares.every((s) => s.included)
                      ? 'ぜんいん'
                      : 'いちぶ',
                  expanded: _showBreakdown,
                  onToggle: (value) {
                    setState(() => _showBreakdown = value);
                  },
                  child: Column(
                    children: _memberShares.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: s.included,
                              onChanged: (v) {
                                setState(() {
                                  s.included = v ?? false;
                                  if (!s.included) {
                                    s.controller.text = '';
                                  }
                                  _recalcShares();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _IconInitial(name: s.name),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              width: 110,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: s.controller,
                                enabled: s.included,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixText: '¥ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _onDeleteRecord,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('このきろくをけす'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
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

  Future<void> _onDeleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('おしはらいをけす'),
        content: const Text(
          'このおしはらいをけしていい？\n'
          'もとにもどせないよ。（モック）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('けす'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.pop();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _SoftInputCard extends StatelessWidget {
  const _SoftInputCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(12, 0, 0, 0),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.grey.shade600),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? summary;
  final bool expanded;
  final ValueChanged<bool> onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: expanded ? theme.colorScheme.primary.withOpacity(0.4) : Colors.grey.shade200,
          style: expanded ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(10, 0, 0, 0),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onToggle(!expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: theme.hintColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary != null)
                          Text(
                            summary!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _IconInitial extends StatelessWidget {
  const _IconInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade200,
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
