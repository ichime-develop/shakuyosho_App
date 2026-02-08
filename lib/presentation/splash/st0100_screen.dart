import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';

class St0100SplashScreen extends StatefulWidget {
  const St0100SplashScreen({super.key});
  @override
  State<St0100SplashScreen> createState() => _St0100SplashScreenState();
}

class _St0100SplashScreenState extends State<St0100SplashScreen> {
  bool _didShowError = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // TODO: 起動時の初期データ取得（Firebase移行時にここへ追加）
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/to0100');
    } catch (e, st) {
      if (_didShowError) return;
      _didShowError = true;
      if (!mounted) return;
      final err = toAppError(e, st);
      await showAppErrorDialog(context: context, error: err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ST0100 スプラッシュ（かり）')),
    );
  }
}
