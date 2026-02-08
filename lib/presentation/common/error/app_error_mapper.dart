/// 例外を AppError に変換して共通のエラールールに揃えるためのファイル。
/// 画面側で try-catch を増やさないための変換ポイント。
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';

AppError toAppError(Object error, StackTrace stackTrace) {
  if (error is AppError) return error;

  // TODO: FirebaseException / PlatformException などを型で分類する
  return AppError(
    type: AppErrorType.unknown,
    userMessage: 'よきせぬエラーが はっせいしました',
    message: error.toString(),
    cause: error,
    stackTrace: stackTrace,
  );
}
