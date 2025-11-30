
import 'package:flutter/material.dart';

/// TO0200: グループ作成/参加ハーフモーダル
///
/// TO0100（トップ/イベントタブ）の「＋」ボタンから表示される、
/// グループ（イベント）を「作成する / 参加する」を選ぶためのシート用 UI。
///
/// 実際の表示は `showModalBottomSheet` 側で行い、
/// 画面遷移などはコールバック経由で呼び出し元（TO0100）に任せる。
class To0200GroupEntrySheet extends StatelessWidget {
  const To0200GroupEntrySheet({
    super.key,
    required this.onTapCreateGroup,
    required this.onTapJoinGroup,
    required this.onTapCancel,
  });

  /// 「グループを作成する」押下時の処理
  final VoidCallback onTapCreateGroup;

  /// 「グループに参加する」押下時の処理
  final VoidCallback onTapJoinGroup;

  /// 「キャンセル」押下時の処理
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // ドラッグハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // タイトル
            Text(
              'さあ、新しいイベントを始めよう！',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'グループを作成するか、既にあるグループに参加して\n'
              'みんなとのお金のやりとりを記録できます。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),

            // グループ作成ボタン
            FilledButton(
              onPressed: onTapCreateGroup,
              child: const Text('グループを作成する'),
            ),
            const SizedBox(height: 8),

            // グループ参加ボタン
            OutlinedButton(
              onPressed: onTapJoinGroup,
              child: const Text('グループに参加する'),
            ),
            const SizedBox(height: 8),

            // キャンセル
            TextButton(
              onPressed: onTapCancel,
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
}
