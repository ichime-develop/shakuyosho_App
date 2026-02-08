import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shakuyousho_app/application/providers/friend_providers.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

/// QR コード読み取り画面
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR コードを よみとる',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.title,
                fontWeight: AppFontWeights.appBarTitle,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // スキャンエリア ガイド
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF36E28C), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = _extractCode(barcode.rawValue!);
    if (code == null) return;

    _handled = true;
    await _controller.stop();
    if (!mounted) return;

    final result = await ref
        .read(friendActionsProvider.notifier)
        .addFriendByCode(code, source: 'qr');

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
      // 失敗時はスキャン再開
      _handled = false;
      await _controller.start();
    }
  }

  /// `shakuyousho://invite?code=SYY-XXXXX` → `SYY-XXXXX` を抽出。
  /// コード文字列が直接入っている場合もサポート。
  String? _extractCode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'shakuyousho' && uri.host == 'invite') {
      return uri.queryParameters['code'];
    }
    // コードが直接埋め込まれている場合
    final trimmed = raw.trim();
    if (RegExp(r'^SYY-[A-Z0-9]{5}$', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }
}
