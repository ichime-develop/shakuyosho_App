import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'router/app_router.dart';
import 'core/utils/app_logger.dart';
import 'presentation/common/app_paper_background.dart';

/// ─────────────────────────────────────────────────────────
/// しゃくよーしょ: アプリのエントリポイント（Composition Root）
/// ここでは【初期化／エラーハンドリング／DIの根／ルータ注入】だけ行う。
/// 画面遷移の詳細やビジネスロジックは Screen/Controller/Provider 側に分離する。
/// ─────────────────────────────────────────────────────────

// 将来 SDK を入れる時のフラグ（Firebase / Sentry など）。
// 実導入時は true にし、該当コードのコメントアウトを外すだけで接続できる。
const bool kUseFirebase = false;
const bool kUseSentry = false;
const Color _appBgColor = Color(0xFFFFF8DC);

void main() {
  // runZonedGuarded 内で binding 初期化〜runApp までを同じ Zone で実行し、
  // "Zone mismatch" 警告を避ける。
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1) プラットフォーム初期化（必要なら向き固定など）
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

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

      // 3.5) Hive 初期化（Map保存）
      await Hive.initFlutter();
      await _openMapBox('eventMetas');
      await _openMapBox('transactions');
      await _openMapBox('threads');
      await _openMapBox('users');
      await _openMapBox('loans');
      await _openMapBox('friends');
      await _openMapBox('messages');

      // 4) 依存注入の根：ProviderScope（全Providerのルート）。
      runApp(
        const ProviderScope(observers: [AppRiverpodLogger()], child: App()),
      );
    },
    (error, stack) {
      // if (kUseFirebase) FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // if (kUseSentry)   Sentry.captureException(error, stackTrace: stack);
    },
  );
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // コールド起動時の初期リンク
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (_) {
      // MissingPluginException / PlatformException は無視
      // （テスト実行時やプラグイン未登録環境で発生し得る）
    }

    // アプリ起動中のリンク受信
    try {
      _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
    } catch (_) {
      // プラグイン未登録時はストリームも失敗し得る
    }
  }

  void _handleDeepLink(Uri uri) {
    // shakuyousho://invite?code=SYY-XXXXX → /invite?code=SYY-XXXXX
    if (uri.host == 'invite' || uri.path == '/invite') {
      final code = uri.queryParameters['code'] ?? '';
      if (code.isNotEmpty) {
        final router = ref.read(appRouterProvider);
        router.go('/invite?code=$code');
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 5) ルータ注入（定義は router/app_router.dart 側）。
    final router = ref.watch(appRouterProvider);

    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Yomogi',
      scaffoldBackgroundColor: _appBgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _appBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final transparentTheme = baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: baseTheme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        );

        return AppPaperBackground(
          child: Theme(
            data: transparentTheme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      // locale / localizationsDelegates / supportedLocales を追加する場合はここに記述。
    );
  }
}

Future<Box<Map>> _openMapBox(String name) async {
  try {
    return await Hive.openBox<Map>(name);
  } on HiveError catch (_) {
    // 旧HiveType保存のボックスが残っている場合は削除して再作成
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox<Map>(name);
  }
}

// _RiverpodLogger removed — AppRiverpodLogger is used from core/utils/app_logger.dart
