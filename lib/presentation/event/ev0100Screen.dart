import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Ev0100EventListScreen extends ConsumerWidget {
  const Ev0100EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('EV0100 Events')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Event list (placeholder)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/to0100'),
              child: const Text('戻る TO0100'),
            ),
          ],
        ),
      ),
    );
  }
}
