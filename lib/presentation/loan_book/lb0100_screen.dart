import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';

/// LB0100: 借用書（個人起点のみ）作成・編集・プレビュー（モック）
/// - 1対1（個人）の借用書を作る。イベント起点からは遷移しない。
/// - 将来：共有リンク発行、PDF化、署名フローを Infrastructure 層で置き換え
class Lb0100IouScreen extends ConsumerStatefulWidget {
  const Lb0100IouScreen({super.key, required this.friendId});

  final String friendId;

  @override
  ConsumerState<Lb0100IouScreen> createState() => _Lb0100IouScreenState();
}

class _Lb0100IouScreenState extends ConsumerState<Lb0100IouScreen> {
  final _formKey = GlobalKey<FormState>();

  // 入力モデル（個人モード固定）
  late String _friendId;
  final _amountCtrl = TextEditingController();
  DateTime? _dueAt;
  final _memoCtrl = TextEditingController();
  bool _requireSignature = true;

  @override
  void initState() {
    super.initState();
    _friendId = widget.friendId;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
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
        title: const Text('LB0100 しゃくようしょ'),
        actions: [
          IconButton(
            tooltip: 'プレビュー',
            onPressed: _onPreview,
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: 'したがきをほぞん',
            onPressed: _onSaveDraft,
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // 個人モード固定のため、モード切替は削除
            _Labeled(
              label: 'あいて（ひっす）',
              child: DropdownButtonFormField<String>(
                value: _friendId,
                items: _mockFriends
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.friendId,
                        child: Text(f.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _friendId = v ?? _friendId),
                validator: (v) => v == null ? 'あいてをえらんでね' : null,
              ),
            ),
            const SizedBox(height: 8),

            _Labeled(
              label: 'きんがく（ひっす・${AppStrings.amountUnit}）',
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '¥ '),
                validator: (v) {
                  final n = int.tryParse((v ?? '').replaceAll(',', ''));
                  if (n == null || n <= 0) {
                    return '1${AppStrings.amountUnit}いじょうをいれてね';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            _Labeled(
              label: 'めやすのひ（にんい）',
              child: InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(hintText: 'まだきめてない'),
                  child: Text(_dueAt == null ? 'まだきめてない' : _fmtDate(_dueAt!)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            _Labeled(
              label: 'メモ（にんい）',
              child: TextFormField(
                controller: _memoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'れい: らんちだい / ホテルだいたてかえ など',
                ),
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: _requireSignature,
              onChanged: (v) => setState(() => _requireSignature = v),
              title: const Text('サインをひっすにする（モック）'),
              subtitle: const Text('あいてのOKのときにサインをたのむよ'),
            ),
            const SizedBox(height: 16),

            // 下部アクション
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onPreview,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('プレビュー'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _onIssue,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('はっこう（きょうゆう）'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ヒント
            Text(
              'メモはしゃくようしょにもそのままだよ。はっこうしたらリンクできょうゆうできるよ（モック）。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _dueAt ?? now,
    );
    if (picked != null) setState(() => _dueAt = picked);
  }

  void _onPreview() {
    if (!_validateSilent()) return;
    final data = _collect();
    _showPreviewSheet(context, data);
  }

  void _onSaveDraft() {
    if (!_validateSilent()) return;
    final data = _collect();
    _Controller.saveDraft(context, data);
  }

  void _onIssue() {
    if (!_formKey.currentState!.validate()) return;
    final data = _collect();
    _Controller.issue(context, data);
  }

  bool _validateSilent() {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ひっすのところがまだだよ')));
    }
    return valid;
  }

  _IouInput _collect() {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    return _IouInput(
      mode: 'personal',
      friendId: _friendId,
      eventId: null,
      amountYen: amount,
      dueAt: _dueAt,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      requireSignature: _requireSignature,
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        child,
      ],
    );
  }
}

void _showPreviewSheet(BuildContext context, _IouInput data) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) {
      final title = data.mode == 'event' ? 'しゃくようしょ（イベント）' : 'しゃくようしょ（こじん）';
      final counterpart = data.mode == 'event'
          ? _mockEvents.firstWhere((e) => e.eventId == data.eventId).title
          : _mockFriends
                .firstWhere((f) => f.friendId == data.friendId)
                .displayName;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('あいて：'),
                        Expanded(
                          child: Text(
                            counterpart,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('きんがく：'),
                        Expanded(
                          child: Text(
                            _fmtYen(data.amountYen),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('めやすのひ：'),
                        Expanded(
                          child: Text(
                            data.dueAt == null
                                ? 'まだきめてない'
                                : _fmtDate(data.dueAt!),
                          ),
                        ),
                      ],
                    ),
                    if (data.memo != null) ...[
                      const SizedBox(height: 8),
                      Text('メモ：${data.memo!}'),
                    ],
                    const SizedBox(height: 8),
                    Text('サインひつよう：${data.requireSignature ? 'ひつよう' : 'おこのみ'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('プレビューをとじたよ')));
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}

/// ---------------------------
/// Controller（最小・モック）
/// ---------------------------
class _Controller {
  static void saveDraft(BuildContext context, _IouInput data) {
    // TODO: Repository を通して下書き保存
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('したがきをほぞんしたよ（モック）')));
  }

  static void issue(BuildContext context, _IouInput data) {
    // TODO: 共有リンク発行、相手へ送信
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('しゃくようしょをつくってリンクをだしたよ（モック）')));
    context.go('/to0100/personal');
  }
}

/// ---------------------------
/// 型・モックデータ（このファイル内に集約）
/// ---------------------------
class _IouInput {
  final String mode; // personal | event
  final String? friendId;
  final String? eventId;
  final int amountYen;
  final DateTime? dueAt;
  final String? memo;
  final bool requireSignature;
  _IouInput({
    required this.mode,
    required this.friendId,
    required this.eventId,
    required this.amountYen,
    required this.dueAt,
    required this.memo,
    required this.requireSignature,
  });
}

class FriendLite {
  final String friendId;
  final String displayName;
  const FriendLite(this.friendId, this.displayName);
}

class EventLite {
  final String eventId;
  final String title;
  const EventLite(this.eventId, this.title);
}

final _mockFriends = <FriendLite>[
  const FriendLite('u_ayaka', 'あやか'),
  const FriendLite('u_sakaguchi', 'さかぐち'),
  const FriendLite('u_kenta', 'けんた'),
  const FriendLite('u_miki', 'みき'),
];

final _mockEvents = <EventLite>[
  const EventLite('ev_001', '箱根旅行(2024/05)'),
  const EventLite('ev_002', '夏フェス(2024/08)'),
  const EventLite('ev_003', '忘年会(2024/12)'),
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

String _fmtDate(DateTime d) {
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
