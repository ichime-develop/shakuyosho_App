import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';

class My0101NameEditScreen extends ConsumerStatefulWidget {
  const My0101NameEditScreen({super.key});

  @override
  ConsumerState<My0101NameEditScreen> createState() =>
      _My0101NameEditScreenState();
}

class _My0101NameEditScreenState extends ConsumerState<My0101NameEditScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentUserProvider);
    _controller = TextEditingController(text: current?.displayName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _controller.text.trim();
    return text.isNotEmpty && text.length <= 8;
  }

  void _onSave() {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 8) return;
    final myId = ref.read(currentUserIdProvider);
    final repo = ref.read(userRepositoryProvider);
    final current = repo.getById(myId);
    final updated =
        (current ??
                User(id: myId, displayName: text, createdAt: DateTime.now()))
            .copyWith(displayName: text);
    repo.upsert(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('なまえをへんしゅう'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 8,
              decoration: const InputDecoration(
                hintText: 'なまえをいれてね',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('もどる'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? _onSave : null,
                    child: const Text('ほぞん'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
