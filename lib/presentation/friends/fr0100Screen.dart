import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../common/common_bottom_nav_bar.dart';

class Fr0100FriendsScreen extends ConsumerWidget {
  const Fr0100FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('FR0100 Friends')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Friends list (placeholder)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/to0100'),
              child: const Text('戻る TO0100'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }
}
