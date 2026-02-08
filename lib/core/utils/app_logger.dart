import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLog {
  static const String _ns = 'SYY'; // Shakuyousho short prefix

  static void i(String msg, {BuildContext? ctx, Map<String, Object?> data = const {}}) {
    _log('INFO', msg, ctx: ctx, data: data);
  }

  static void d(String msg, {BuildContext? ctx, Map<String, Object?> data = const {}}) {
    if (kDebugMode) _log('DEBUG', msg, ctx: ctx, data: data);
  }

  static void w(String msg, {BuildContext? ctx, Object? error, Map<String, Object?> data = const {}}) {
    _log('WARN', msg, ctx: ctx, error: error, data: data);
  }

  static void e(String msg, {BuildContext? ctx, Object? error, StackTrace? stack, Map<String, Object?> data = const {}}) {
    _log('ERROR', msg, ctx: ctx, error: error, stack: stack, data: data);
  }

  static void ui(String event, {BuildContext? ctx, Map<String, Object?> data = const {}}) {
    _log('UI', event, ctx: ctx, data: data);
  }

  static void nav(String event, {BuildContext? ctx, Map<String, Object?> data = const {}}) {
    _log('NAV', event, ctx: ctx, data: data);
  }

  static void _log(String level, String msg, {BuildContext? ctx, Object? error, StackTrace? stack, Map<String, Object?> data = const {}}) {
    final location = ctx != null ? _widgetPath(ctx) : null;
    if (kDebugMode) {
      debugPrint('[$level][$_ns] ${location ?? '-'} :: $msg ${data.isEmpty ? '' : data}');
    }
    dev.log('$level $_ns', name: '$_ns.$level', error: error, stackTrace: stack);
  }

  static String _widgetPath(BuildContext ctx) {
    final el = ctx as Element;
    final route = ModalRoute.of(ctx)?.settings.name;
    final w = el.widget.runtimeType;
    return route != null ? '$w@$route' : w.toString();
  }
}

/// Riverpod: 値更新ログ（Debugのみ）
class AppRiverpodLogger extends ProviderObserver {
  const AppRiverpodLogger();

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    final name = provider.name ?? provider.runtimeType.toString();
    debugPrint('[PROV][SYY] $name -> $newValue');
  }
}

/// 画面 State で使えるミニMixin
mixin ScreenLogMixin<T extends StatefulWidget> on State<T> {
  @protected
  void logInit(String screenId) => AppLog.d('initState', data: {'screen': screenId});
  @protected
  void logDispose(String screenId) => AppLog.d('dispose', data: {'screen': screenId});
  @protected
  void logBuild(BuildContext context, String screenId) => AppLog.d('build', ctx: context, data: {'screen': screenId});
}
