// AppError をUIに表示し、ルールに沿って遷移も行うダイアログ用ファイル。
// 共通エラー文言（S001など）もここから表示する。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/presentation/common/error/app_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_message_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

Future<void> showAppErrorDialog({
  required BuildContext context,
  required AppError error,
}) async {
  AppLog.e(
    'app_error_dialog',
    error: error.cause ?? error,
    stack: error.stackTrace,
    data: {
      'type': error.type.toString(),
      'message': error.message,
    },
  );

  final commonMessageId = switch (error.type) {
    AppErrorType.network => AppMessageId.s001,
    AppErrorType.notFound => AppMessageId.s002,
    AppErrorType.unknown => AppMessageId.s003,
    _ => null,
  };

  Future<void> handlePrimary() async {
    final router = GoRouter.of(context);
    switch (error.type) {
      case AppErrorType.network:
      case AppErrorType.notFound:
        router.go('/to0100/personal');
        return;
      case AppErrorType.invalid:
        return;
      case AppErrorType.unauthorized:
        return;
      case AppErrorType.unknown:
        router.go('/st0100');
        return;
    }
  }

  if (error.userMessage.isEmpty && commonMessageId != null) {
    await showAppMessageDialog(
      context: context,
      messageId: commonMessageId,
      onPrimary: handlePrimary,
      closeOnPrimarySuccess: false,
    );
    return;
  }

  final fallback =
      commonMessageId == null
          ? 'よきせぬエラーが はっせいしました'
          : AppMessages.dialog(commonMessageId).message;
  final message = error.userMessage.isNotEmpty ? error.userMessage : fallback;

  await showAppDialog(
    context: context,
    title: 'えらー',
    message: message,
    actions: [
      AppDialogAction(
        label: 'OK',
        style: AppDialogActionStyle.primary,
        onPressedAsync: handlePrimary,
        closeOnSuccess: false,
      ),
    ],
  );
}
