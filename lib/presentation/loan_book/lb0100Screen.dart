import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Lb0100IouScreen extends ConsumerWidget {
  const Lb0100IouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('LB0100 借用書（仮）')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('借用書プレビュー（仮）'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.go('/to0100'), child: const Text('戻る TO0100')),
          ],
        ),
      ),
    );
  }
}
