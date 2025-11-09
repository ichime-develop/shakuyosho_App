import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Ev0200EventDetailScreen extends ConsumerWidget {
  const Ev0200EventDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = Uri.base.queryParameters['eventId'] ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('EV0200 Event Detail'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Event Detail for: $eventId'),
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
