import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/common_bottom_nav_bar.dart';

class My0100Screen extends ConsumerWidget {
  const My0100Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY0100 My')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('My / Settings (placeholder)'),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 2),
    );
  }
}
