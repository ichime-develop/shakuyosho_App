import 'package:flutter/material.dart';

/// 画面内で使う共通ローディング表示（全画面は使わない）
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key, this.message = 'よみこみちゅう...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
