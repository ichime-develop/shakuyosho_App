import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/contacts_mock.dart';

class Gr0200GroupJoinScreen extends ConsumerStatefulWidget {
  const Gr0200GroupJoinScreen({super.key});

  @override
  ConsumerState<Gr0200GroupJoinScreen> createState() =>
      _Gr0200GroupJoinScreenState();
}

class _Gr0200GroupJoinScreenState
    extends ConsumerState<Gr0200GroupJoinScreen> {
  final _eventIdController = TextEditingController();

  @override
  void dispose() {
    _eventIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventId = _eventIdController.text.trim();
    final canJoin = eventId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('GR0200 グループさんか'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('イベントIDをいれてね'),
            const SizedBox(height: 8),
            TextField(
              controller: _eventIdController,
              decoration: const InputDecoration(
                hintText: 'ev_...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canJoin ? _onJoin : null,
                child: const Text('さんかする'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onJoin() async {
    final eventId = _eventIdController.text.trim();
    if (eventId.isEmpty) return;

    try {
      final joinedId = await ref.read(eventStateProvider.notifier).joinEvent(
            eventId: eventId,
            participantId: mockLoginUserId,
          );
      if (!mounted) return;
      context.push('/ev0200?eventId=$joinedId');
    } on StateError catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message ?? 'イベントが見つかりません')),
      );
    }
  }
}
