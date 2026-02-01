import 'dart:async';

import 'package:flutter/material.dart';

import 'app_loading_screen.dart';

/// 画面遷移直後に「ローディング画面」を挿入するためのゲート。
///
/// - [load] が完了するまで child の代わりにローディングを表示
/// - [showDelay] を過ぎても load が終わらない場合だけ表示するため、
///   速い処理でのチラつきを抑える
class AppRouteLoadingGate extends StatefulWidget {
  const AppRouteLoadingGate({
    super.key,
    required this.child,
    required this.load,
    this.message = 'よみこみちゅう…',
    this.showDelay = const Duration(milliseconds: 120),
  });

  final Widget child;
  final Future<void> Function() load;
  final String message;
  final Duration showDelay;

  @override
  State<AppRouteLoadingGate> createState() => _AppRouteLoadingGateState();
}

class _AppRouteLoadingGateState extends State<AppRouteLoadingGate> {
  bool _done = false;
  bool _show = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(widget.showDelay, () {
      if (!mounted || _done) return;
      setState(() => _show = true);
    });

    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await widget.load();
    } finally {
      _done = true;
      _timer?.cancel();
    }

    if (!mounted) return;
    setState(() {
      _show = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return AppLoadingScreen(message: widget.message);
    }
    return widget.child;
  }
}
