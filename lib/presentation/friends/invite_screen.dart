import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/friend_providers.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';

/// 招待リンク経由で開かれる確認画面
/// shakuyousho://invite?code=SYY-XXXXX
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final userRepo = ref.watch(userRepositoryProvider);
    final peer = userRepo.getByCode(widget.code);
    final peerName = peer?.displayName ?? '???';
    final isSelf = peer?.id == ref.watch(currentUserIdProvider);
    final isNotFound = peer == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ともだち しょうたい'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/fr0100'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アバター
              CircleAvatar(
                radius: 40,
                backgroundColor: isNotFound
                    ? Colors.grey.shade300
                    : const Color(0xFF36E28C).withValues(alpha: 0.2),
                child: Text(
                  isNotFound ? '?' : peerName.characters.first,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isNotFound ? Colors.grey : const Color(0xFF36E28C),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // メッセージ
              if (isNotFound)
                const Text(
                  'コードに あてはまる\nユーザーが みつかりません',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )
              else if (isSelf)
                const Text(
                  'これは じぶんの コードです',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )
              else ...[
                Text(
                  '$peerName さんと',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'ともだちに なる？',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'コード: ${widget.code}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],

              const SizedBox(height: 32),

              // ボタン
              if (!isNotFound && !isSelf)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _processing ? null : _onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF36E28C),
                      foregroundColor: const Color(0xFF111714),
                      shape: const StadiumBorder(),
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'ともだちに なる！',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/fr0100'),
                child: const Text('もどる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept() async {
    setState(() => _processing = true);

    final result = await ref
        .read(friendActionsProvider.notifier)
        .addFriendByCode(widget.code, source: 'link');

    if (!mounted) return;

    final message = switch (result) {
      AddFriendResult.success => 'ともだちに なりました！',
      AddFriendResult.notFound => 'ユーザーが みつかりません',
      AddFriendResult.selfAdd => 'じぶんの コードです',
      AddFriendResult.alreadyFriend => 'すでに ともだちです',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (result == AddFriendResult.success) {
      context.go('/fr0100');
    } else {
      setState(() => _processing = false);
    }
  }
}
