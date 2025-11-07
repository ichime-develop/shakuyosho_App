import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Sv0100SettlementScreen extends ConsumerWidget {
  const Sv0100SettlementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = Uri.base.queryParameters['eventId'] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('SV0100 Settlement')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settlement for: $eventId'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
