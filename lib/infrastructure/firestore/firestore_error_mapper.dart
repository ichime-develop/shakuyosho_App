import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';

/// Firestore の例外を AppError に変換する。
AppError mapFirestoreError(
  Object error,
  StackTrace stackTrace, {
  required String operation,
}) {
  if (error is AppError) return error;
  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    if (code == 'permission-denied' || code == 'unauthenticated') {
      return AppError(
        type: AppErrorType.unauthorized,
        userMessage: '',
        message: '$operation failed: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == 'not-found') {
      return AppError(
        type: AppErrorType.notFound,
        userMessage: '',
        message: '$operation failed: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == 'invalid-argument' || code == 'failed-precondition') {
      return AppError(
        type: AppErrorType.invalid,
        userMessage: '',
        message: '$operation failed: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'resource-exhausted') {
      return AppError(
        type: AppErrorType.network,
        userMessage: '',
        message: '$operation failed: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
  return AppError(
    type: AppErrorType.unknown,
    userMessage: '',
    message: '$operation failed: $error',
    cause: error,
    stackTrace: stackTrace,
  );
}
