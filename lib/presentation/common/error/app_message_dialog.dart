// AppMessages のIDからダイアログを生成して表示するヘルパーファイル。
// 画面側は messageId と必要なコールバックだけ渡せばよい。
import 'package:flutter/material.dart';
import 'package:shakuyousho_app/presentation/common/error/app_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

Future<void> showAppMessageDialog({
  required BuildContext context,
  required String messageId,
  Future<void> Function()? onPrimary,
  Future<void> Function()? onCancel,
  Future<void> Function()? onDestructive,
  bool closeOnPrimarySuccess = true,
  bool closeOnCancelSuccess = true,
  bool closeOnDestructiveSuccess = true,
  bool closeOnPrimaryFailure = true,
  bool closeOnCancelFailure = true,
  bool closeOnDestructiveFailure = true,
  bool barrierDismissible = true,
}) async {
  final msg = AppMessages.dialog(messageId);
  final title = msg.title.trim().isEmpty ? null : msg.title;

  final actions =
      msg.buttons.map((button) {
        switch (button.role) {
          case AppDialogButtonRole.primary:
            return AppDialogAction(
              label: button.label,
              style: AppDialogActionStyle.primary,
              onPressedAsync: onPrimary,
              closeOnSuccess: closeOnPrimarySuccess,
              closeOnFailure: closeOnPrimaryFailure,
            );
          case AppDialogButtonRole.cancel:
            return AppDialogAction(
              label: button.label,
              style: AppDialogActionStyle.secondary,
              onPressedAsync: onCancel,
              closeOnSuccess: closeOnCancelSuccess,
              closeOnFailure: closeOnCancelFailure,
            );
          case AppDialogButtonRole.destructive:
            return AppDialogAction(
              label: button.label,
              style: AppDialogActionStyle.destructive,
              onPressedAsync: onDestructive,
              closeOnSuccess: closeOnDestructiveSuccess,
              closeOnFailure: closeOnDestructiveFailure,
            );
        }
      }).toList(growable: false);

  await showAppDialog(
    context: context,
    title: title,
    message: msg.message,
    actions: actions,
    barrierDismissible: barrierDismissible,
  );
}
