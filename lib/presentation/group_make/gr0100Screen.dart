import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Gr0100GroupCreateScreen extends ConsumerWidget {
  const Gr0100GroupCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('GR0100 Group Create')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('グループ作成（仮）'),
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
