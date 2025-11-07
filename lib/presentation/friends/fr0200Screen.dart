import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Fr0200FriendDetailScreen extends ConsumerWidget {
  const Fr0200FriendDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendId = Uri.base.queryParameters['friendId'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('FR0200 Friend Detail')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Friend Detail for: $friendId'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
