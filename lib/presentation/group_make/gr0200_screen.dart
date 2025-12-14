import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Gr0200GroupJoinScreen extends ConsumerWidget {
  const Gr0200GroupJoinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('GR0200 グループさんか'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('グループさんか（かり）'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/to0100'),
              child: const Text('TO0100 にもどる'),
            ),
          ],
        ),
      ),
    );
  }
}
