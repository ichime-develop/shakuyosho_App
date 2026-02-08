/// アプリ全体で共通に使うエラー型と分類を定義するファイル。
/// Repository/Provider/UI で同じエラー構造を共有するための土台。
enum AppErrorType {
  network, // 通信できない / タイムアウト
  notFound, // データが存在しない
  invalid, // 入力値・状態が不正（画面固有）
  unauthorized, // 認証・権限（将来用）
  unknown, // 想定外エラー
}

class AppError implements Exception {
  final AppErrorType type;
  final String userMessage; // UI表示用（必須）
  final String? message; // ログ用
  final Object? cause;
  final StackTrace? stackTrace;

  const AppError({
    required this.type,
    required this.userMessage,
    this.message,
    this.cause,
    this.stackTrace,
  });
}
