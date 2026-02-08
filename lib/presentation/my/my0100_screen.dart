import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import '../common/common_bottom_nav_bar.dart';

/// MY0100: じぶん（プロフィール/設定）
/// - プロフィール表示（名前/ユーザーID）
/// - 通知ON/OFF、簡易生体認証ON/OFF（モック）
/// - 表示設定（通貨/テーマ：モック）
/// - データエクスポート/キャッシュクリア/サインアウトなどの導線（モック）
class My0100Screen extends ConsumerStatefulWidget {
  const My0100Screen({super.key});

  @override
  ConsumerState<My0100Screen> createState() => _My0100ScreenState();
}

class _My0100ScreenState extends ConsumerState<My0100Screen> {
  bool _codeCopied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AppLog.i('open screen', ctx: context, data: {'screen': 'MY0100'});
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.displayName ?? 'あなた';
    final userId = currentUser?.id ?? ref.watch(currentUserIdProvider);
    final myCode = currentUser?.myCode ?? '---';
    final inviteUrl = 'shakuyousho://invite?code=$myCode';

    return Scaffold(
      appBar: AppBar(title: const Text('まいぺーじ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── プロフィール
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'ゆーざーあいでぃー: $userId',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // ── ともだちコード ──
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ともだちコード: $myCode',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: myCode),
                                );
                                setState(() => _codeCopied = true);
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    setState(() => _codeCopied = false);
                                  }
                                });
                              },
                              child: Icon(
                                _codeCopied ? Icons.check : Icons.copy,
                                size: 16,
                                color: _codeCopied
                                    ? const Color(0xFF36E28C)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => Share.share(
                                'しゃくようしょ で ともだちに なろう！\n$inviteUrl',
                              ),
                              child: const Icon(
                                Icons.share,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _Controller.onEditProfile(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('へんしゅう'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── なまえをへんしゅう
          Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('なまえをへんしゅう'),
                onTap: () => _Controller.onEditProfile(context),
              ),
              const Divider(height: 1),
            ],
          ),
          const SizedBox(height: 12),

          // ── あぷりじょうほう / りようきやく / ぷらいばしー（カードではなく単一のリスト）
          Text('あぷりじょうほう', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('ばーじょん'),
                subtitle: const Text('1.0.0'),
                onTap: () => _Controller.onOpenAbout(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('りようきやく（あとで）'),
                onTap: () => _Controller.onOpenTerms(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('ぷらいばしー（あとで）'),
                onTap: () => _Controller.onOpenPrivacy(context),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 3),
    );
  }
}

/// ---------------------------
/// 簡易コントローラ（ハンドラ集約）
/// ---------------------------
class _Controller {
  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static void onEditProfile(BuildContext context) {
    context.push('/my0101');
  }

  static void onOpenAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'しゃくよーしょ',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.receipt_long_outlined),
      children: const [Text('ともだちやイベントのおかねのかりかえを、かるくメモしてまとめられるアプリだよ。')],
    );
  }

  static void onOpenTerms(BuildContext context) {
    _toast(context, 'りようきやくはあとでたいおうするよ');
  }

  static void onOpenPrivacy(BuildContext context) {
    _toast(context, 'ぷらいばしーはあとでたいおうするよ');
  }
}
