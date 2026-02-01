import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/thread_providers.dart';

/// FR0200: スレッド詳細（個人/グループ共通）
class Fr0200ThreadDetailScreen extends ConsumerWidget {
  const Fr0200ThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (threadId.isEmpty) {
      return _ThreadErrorView(
        message: 'threadId が未指定です。',
        onBack: () => context.go('/fr0100'),
      );
    }

    final detail = ref.watch(threadDetailProvider(threadId));
    if (detail == null) {
      return _ThreadErrorView(
        message: 'スレッドが見つかりません。',
        onBack: () => context.go('/fr0100'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(detail.title),
      ),
      body: const Center(
        child: Text('このスレッドのやりとりがここに表示されます'),
      ),
    );
  }
}

class _ThreadErrorView extends StatelessWidget {
  const _ThreadErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title: const Text('FR0200'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextButton(onPressed: onBack, child: const Text('FR0100にもどる')),
            ],
          ),
        ),
      ),
    );
  }
}
