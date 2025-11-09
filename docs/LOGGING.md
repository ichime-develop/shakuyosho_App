# しゃくよーしょ — ロギング方針（Developer docs）

このドキュメントは、アプリ内でのログ出力方針と使い方をまとめたものです。
デバッグ、バグ調査、動作確認のために軽量で一貫したログを出す仕組みを導入しています。

目的
- 画面遷移（NAV）、ユーザー操作（UI）、画面ライフサイクル、Provider の状態変化を簡潔にログ化。
- 開発時に素早く原因特定できるように、共通フォーマットで出力。
- 本番では極力出力を抑え、必要なら Sentry / Crashlytics 等へブリッジする。

導入ファイル（実装箇所）
- `lib/core/utils/app_logger.dart`
  - 軽量ロガー `AppLog`（API: `i`, `d`, `w`, `e`, `ui`, `nav`）
  - `AppRiverpodLogger`（Riverpod の ProviderObserver、debug 時のみログ）
  - `ScreenLogMixin`（State 用 mixin: `logInit`, `logBuild`, `logDispose`）

- `lib/core/utils/route_logger.dart`
  - `RouteLogger`（NavigatorObserver 実装）。push/pop/replace を自動で `[NAV]` ログ出力。
  - `goRouterObserversProvider`（GoRouter 用の observers Provider）

- ルータと起動時の接続箇所
  - `lib/router/app_router.dart` に `observers: ref.read(goRouterObserversProvider)` を差し込み。
  - `lib/main.dart` の `ProviderScope` に `AppRiverpodLogger` を登録（`observers: [AppRiverpodLogger()]`）。

ログのフォーマット（開発時）
- 画面/UI/ナビゲーションは debug 出力に次のように出ます:
  - [NAV][SYY] push/pop: ルート遷移情報
  - [UI][SYY] bottom_nav_tap: ボトムナビ操作
  - [DEBUG][SYY] build/init/dispose: 画面ライフサイクル（ScreenLogMixin 経由）
  - [PROV][SYY] ProviderName -> 新しい値（Provider 更新時）

使い方（例）
- 画面をログ化する（StatefulWidget）:
```dart
class _MyScreenState extends State<MyScreen> with ScreenLogMixin {
  @override
  void initState() {
    super.initState();
    logInit('MY0100');
  }

  @override
  Widget build(BuildContext context) {
    logBuild(context, 'MY0100');
    return Scaffold(...);
  }

  @override
  void dispose() {
    logDispose('MY0100');
    super.dispose();
  }
}
```

- UI 操作でログを出す（例: ボトムナビ）:
```dart
AppLog.ui('bottom_nav_tap', ctx: context, data: {'index': i, 'dest': 'home'});
```

- 一時的な情報的ログ（例: 画面オープン）:
```dart
AppLog.i('open screen', ctx: context, data: {'screen': 'FR0100'});
```

運用ルール
- debug ビルドではログを多めに出す（`kDebugMode` チェックで制御）。本番では `AppLog.d` などは出力しない。
- 重大なエラーは `AppLog.e` を使い、必要に応じて Sentry / Crashlytics へ転送するラッパーを追加する。
- Provider の重要な状態変化や外部API呼び出しの結果は `AppLog.i/w/e` で記録する。

トラブルシュートの手順
1. まず `flutter run` を実行し、コンソールログを確認。
2. 画面遷移が怪しい場合は `NAV` ログを見て push/pop の発生順を確認。
3. UI 操作で期待した反応が無い場合は `UI` ログ（例: bottom_nav_tap）を探す。
4. Provider の値が期待通りでない場合は `PROV` ログで値の変化を追う。
5. 必要なら該当画面に `logBuild` / `AppLog.i` を追加して詳細を取得。

将来的な拡張案
- 本番ログレベルの設定（環境変数／リモートフラグ）を追加して、必要時に詳細ログを収集できるようにする。
- `AppLog` のバックエンド（Sentry / Cloud Logging）への送信プラグを追加。
- ログ出力の構造化（JSON）化してログ集約ツールで解析しやすくする。

変更履歴
- 2025-11-07: 初版（AppLog, RouteLogger, AppRiverpodLogger, ScreenLogMixin を導入）

---

このドキュメントはチームで編集して常に最新化してください。実装を変更したら同時にこのファイルも更新すること。
