/// アプリ共通ダイアログのUIとアクション実行をまとめたファイル。
/// ボタン実行中のローディングやエラー表示の責務もここで完結させる。
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

enum AppDialogActionStyle { primary, secondary, destructive }

class AppDialogAction {
  final String label;
  final AppDialogActionStyle style;
  final Future<void> Function()? onPressedAsync;
  final bool closeOnSuccess;
  final bool closeOnFailure;

  const AppDialogAction({
    required this.label,
    required this.style,
    this.onPressedAsync,
    this.closeOnSuccess = true,
    this.closeOnFailure = true,
  });
}

Future<void> showAppDialog({
  required BuildContext context,
  String? title,
  required String message,
  List<AppDialogAction> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return _AppDialog(
        title: title,
        message: message,
        actions: actions.isEmpty
            ? const [
                AppDialogAction(
                  label: 'OK',
                  style: AppDialogActionStyle.primary,
                ),
              ]
            : actions,
      );
    },
  );
}

class _AppDialog extends StatefulWidget {
  const _AppDialog({required this.message, required this.actions, this.title});

  final String? title;
  final String message;
  final List<AppDialogAction> actions;

  @override
  State<_AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<_AppDialog> {
  bool _loading = false;
  int? _loadingIndex;

  Future<void> _runAction(int index, AppDialogAction action) async {
    if (_loading) return;

    if (action.onPressedAsync == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _loading = true;
      _loadingIndex = index;
    });

    try {
      await action.onPressedAsync!.call();
      if (!mounted) return;
      if (action.closeOnSuccess) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      final rootContext = Navigator.of(context, rootNavigator: true).context;
      final err = toAppError(e, st);
      AppLog.e(
        'app_dialog_error',
        error: err.cause ?? e,
        stack: err.stackTrace ?? st,
        data: {'type': err.type.toString(), 'message': err.message},
      );
      if (mounted && action.closeOnFailure) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        await showAppErrorDialog(context: rootContext, error: err);
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = widget.actions.take(2).toList(growable: false);
    return PopScope(
      canPop: !_loading,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7), // iOSっぽい薄いグレー
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 10),
                  color: Color(0x33000000),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null) ...[
                    Center(
                      child: Text(
                        widget.title!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.section,
                          fontWeight: AppFontWeights.sectionTitle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    widget.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 35),
                  if (actions.length == 1)
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        action: actions.first,
                        loading: _loading && _loadingIndex == 0,
                        onPressed: () => _runAction(0, actions.first),
                        disabled: _loading,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            action: actions[0],
                            loading: _loading && _loadingIndex == 0,
                            onPressed: () => _runAction(0, actions[0]),
                            disabled: _loading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            action: actions[1],
                            loading: _loading && _loadingIndex == 1,
                            onPressed: () => _runAction(1, actions[1]),
                            disabled: _loading,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.loading,
    required this.onPressed,
    required this.disabled,
  });

  final AppDialogAction action;
  final bool loading;
  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dialogBg = Color(0xFFF2F2F7);

    final label = loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _textColor(action.style),
              ),
            ),
          )
        : Text(
            action.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: AppTextSizes.body,
              fontWeight: AppFontWeights.label,
              color: _textColor(action.style),
            ),
          );

    switch (action.style) {
      case AppDialogActionStyle.secondary:
        return OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: dialogBg,
            side: const BorderSide(color: Colors.black, width: 1.2),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: label,
        );
      case AppDialogActionStyle.destructive:
        return OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: dialogBg,
            side: const BorderSide(color: Colors.black, width: 1.2),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: label,
        );
      case AppDialogActionStyle.primary:
      default:
        return ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: AppButtonStyles.primaryPill,
          child: label,
        );
    }
  }

  Color _textColor(AppDialogActionStyle style) {
    switch (style) {
      case AppDialogActionStyle.secondary:
        return Colors.black;
      case AppDialogActionStyle.destructive:
        return AppColors.borrowAmount;
      case AppDialogActionStyle.primary:
      default:
        return AppColors.primaryActionText;
    }
  }
}
