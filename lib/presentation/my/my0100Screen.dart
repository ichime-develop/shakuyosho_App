import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import '../common/common_bottom_nav_bar.dart';

/// MY0100: じぶん（プロフィール/設定）
/// - プロフィール表示（名前/ユーザーID）
/// - 通知ON/OFF、簡易生体認証ON/OFF（モック）
/// - 表示設定（通貨/テーマ：モック）
/// - データエクスポート/キャッシュクリア/サインアウトなどの導線（モック）
class My0100Screen extends ConsumerWidget {
  const My0100Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    AppLog.i('open screen', ctx: context, data: {'screen': 'MY0100'});
    final notifOn = ref.watch(_notifEnabledProvider);
    final bioOn = ref.watch(_biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MY0100 じぶん')),
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
                        Text(
                          _mockProfile.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_mockProfile.userId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _Controller.onEditProfile(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 基本設定
          Text('基本設定', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('プッシュ通知'),
                  subtitle: const Text('返済期限や清算結果などの通知を受け取る'),
                  value: notifOn,
                  onChanged: (v) =>
                      ref.read(_notifEnabledProvider.notifier).state = v,
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('生体認証で起動ロック'),
                  subtitle: const Text('Face/Touch ID（ダミー設定）'),
                  value: bioOn,
                  onChanged: (v) =>
                      ref.read(_biometricEnabledProvider.notifier).state = v,
                  secondary: const Icon(Icons.fingerprint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 表示設定
          Text('表示', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_yen),
                  title: const Text('通貨'),
                  subtitle: const Text('JPY（日本円）'),
                  onTap: () => _Controller.onChangeCurrency(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('テーマ'),
                  subtitle: const Text('システムに合わせる'),
                  onTap: () => _Controller.onChangeTheme(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── データ
          Text('データ', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('データを書き出す（CSV）'),
                  onTap: () => _Controller.onExportCsv(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('キャッシュをクリア'),
                  onTap: () => _Controller.onClearCache(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── その他
          Text('その他', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('バージョン'),
                  subtitle: const Text('0.1.0 (mock)'),
                  onTap: () => _Controller.onOpenAbout(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('サインアウト'),
                  onTap: () => _Controller.onSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 2),
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
    _toast(context, 'プロフィール編集：未実装');
  }

  static void onChangeCurrency(BuildContext context) {
    _toast(context, '通貨選択：未実装（将来は JPY/USD/EUR など）');
  }

  static void onChangeTheme(BuildContext context) {
    _toast(context, 'テーマ変更：未実装（ライト/ダーク/システム）');
  }

  static void onExportCsv(BuildContext context) {
    _toast(context, 'CSVエクスポート：未実装');
  }

  static void onClearCache(BuildContext context) {
    _toast(context, 'キャッシュクリア：未実装');
  }

  static void onOpenAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'しゃくよーしょ',
      applicationVersion: '0.1.0 (mock)',
      applicationIcon: const Icon(Icons.receipt_long_outlined),
      children: const [Text('友人間・イベント単位の貸し借りをシンプルに記録・清算するアプリ。')],
    );
  }

  static void onSignOut(BuildContext context) {
    _toast(context, 'サインアウト：未実装');
  }
}

/// ---------------------------
/// ローカルState（モック）
/// ---------------------------
final _notifEnabledProvider = StateProvider<bool>((ref) => true);
final _biometricEnabledProvider = StateProvider<bool>((ref) => false);

/// ---------------------------
/// モックプロフィール（このファイルに集約）
/// ---------------------------
class UserProfile {
  final String userId;
  final String displayName;
  final String email;
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
  });
}

const _mockProfile = UserProfile(
  userId: 'u_ichikawa',
  displayName: 'いちかわ けいた',
  email: 'keita@example.com',
);
