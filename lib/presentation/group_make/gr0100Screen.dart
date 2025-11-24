import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// GR0100: グループ作成／招待画面（作成者/管理者向け・モック）
/// - 招待コード表示・コピー・共有
/// - QR（仮表示）
/// - 参加メンバーの簡易表示
/// - 「このコードで参加手順へ」押下で GR0200 へ
class Gr0100GroupCreateScreen extends ConsumerWidget {
  const Gr0100GroupCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GR0100 グループ作成/招待'),
        actions: [
          IconButton(
            tooltip: '共有',
            onPressed: () => _Controller.onShare(context, _mockGroup),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // 概要
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_mockGroup.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('招待コード：'),
                      SelectableText(
                        _mockGroup.inviteCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'コピー',
                        onPressed: () => _Controller.onCopyCode(
                          context,
                          _mockGroup.inviteCode,
                        ),
                        icon: const Icon(Icons.copy_all_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '有効期限：${_fmtDate(_mockGroup.expiresAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // QR（仮）
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('QR（仮表示）', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('JOIN:${_mockGroup.inviteCode}'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'このQR/コードを送ると、友だちは GR0200 から参加できます（モック）。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // メンバー（簡易）
          Text('メンバー', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._mockMembers.map(
            (m) => ListTile(
              leading: CircleAvatar(
                child: Text(m.displayName.characters.first),
              ),
              title: Text(m.displayName),
              subtitle: Text(m.isAdmin ? '管理者' : 'メンバー'),
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                _Controller.onGoJoinWithCode(context, _mockGroup.inviteCode),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('このコードで参加手順へ（GR0200）'),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Controller（最小・モック）
/// ---------------------------
class _Controller {
  static void onCopyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('招待コードをコピーしました')));
  }

  static void onShare(BuildContext context, _GroupInvite g) {
    // TODO: 共有実装（Shareプラグイン等）。今はSnackBarのみ。
    final text =
        '「${g.title}」に招待します。コード: ${g.inviteCode}\n有効期限: ${_fmtDate(g.expiresAt)}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static void onGoJoinWithCode(BuildContext context, String code) {
    final uri = Uri(path: '/gr0200', queryParameters: {'code': code});
    context.push(uri.toString());
  }
}

/// ---------------------------
/// 型・モック
/// ---------------------------
class _GroupInvite {
  final String groupId;
  final String title;
  final String inviteCode;
  final DateTime expiresAt;
  const _GroupInvite({
    required this.groupId,
    required this.title,
    required this.inviteCode,
    required this.expiresAt,
  });
}

class _MemberLite {
  final String userId;
  final String displayName;
  final bool isAdmin;
  const _MemberLite(this.userId, this.displayName, {this.isAdmin = false});
}

final _mockGroup = _GroupInvite(
  groupId: 'g_001',
  title: '箱根旅行(2024/05)',
  inviteCode: 'HKNE24',
  expiresAt: DateTime(2026, 1, 31),
);

final _mockMembers = <_MemberLite>[
  const _MemberLite('u_ichikawa', 'いちかわ', isAdmin: true),
  const _MemberLite('u_sakaguchi', 'さかぐち'),
  const _MemberLite('u_ayaka', 'あやか'),
];

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
