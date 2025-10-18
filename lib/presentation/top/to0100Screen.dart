import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class To0100TopScreen extends ConsumerWidget {
  const To0100TopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('TO0100 Top')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(onPressed: () => context.go('/gr0100'), child: const Text('GR0100 へ')),
          ElevatedButton(onPressed: () => context.go('/gr0200'), child: const Text('GR0200 へ')),
          ElevatedButton(onPressed: () => context.go('/tr0100'), child: const Text('TR0100 へ')),
          ElevatedButton(onPressed: () => context.go('/lb0100'), child: const Text('LB0100 へ')),
        ],
      ),
    );
  }
}
