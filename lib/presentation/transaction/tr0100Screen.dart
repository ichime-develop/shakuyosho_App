import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Tr0100TransactionScreen extends ConsumerWidget {
  const Tr0100TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('TR0100 Transaction'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('立替・貸し借りメモ（仮）'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/lb0100'),
            child: const Text('LB0100 借用書へ'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/to0100'),
            child: const Text('戻る TO0100'),
          ),
        ],
      ),
    );
  }
}
