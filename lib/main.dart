import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'core/utils/app_logger.dart';

/// ─────────────────────────────────────────────────────────
/// しゃくよーしょ: アプリのエントリポイント（Composition Root）
/// ここでは【初期化／エラーハンドリング／DIの根／ルータ注入】だけ行う。
/// 画面遷移の詳細やビジネスロジックは Screen/Controller/Provider 側に分離する。
/// ─────────────────────────────────────────────────────────

// 将来 SDK を入れる時のフラグ（Firebase / Sentry など）。
// 実導入時は true にし、該当コードのコメントアウトを外すだけで接続できる。
const bool kUseFirebase = false;
const bool kUseSentry = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) プラットフォーム初期化（必要なら向き固定など）
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 2) 外部SDKの初期化（必要になったらここで）
  if (kUseFirebase) {
    // await Firebase.initializeApp();
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
  if (kUseSentry) {
    // await SentryFlutter.init((o) { o.dsn = 'YOUR_DSN'; });
  }

  // 3) グローバルエラーハンドリング
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // if (kUseFirebase) FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    // if (kUseSentry)   Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  // runZonedGuarded で非同期エラーも拾う
  runZonedGuarded(
    () {
      runApp(
        // 4) 依存注入の根：ProviderScope（全Providerのルート）。
        const ProviderScope(
          // 開発時に変更検知したい場合は observers に Logger を追加する。
          observers: [AppRiverpodLogger()],
          child: App(),
        ),
      );
    },
    (error, stack) {
      // if (kUseFirebase) FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // if (kUseSentry)   Sentry.captureException(error, stackTrace: stack);
    },
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5) ルータ注入（定義は router/app_router.dart 側）。
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(useMaterial3: true),
      // locale / localizationsDelegates / supportedLocales を追加する場合はここに記述。
    );
  }
}

// _RiverpodLogger removed — AppRiverpodLogger is used from core/utils/app_logger.dart
