import 'package:flutter/material.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

/// 改行入力を使うフィールド向けに、キーボード上へ「かんりょう」ボタンを出す共通部品。
///
/// この Widget は Stack の子として配置して使用する。
class AppKeyboardDoneBar extends StatefulWidget {
  const AppKeyboardDoneBar({
    super.key,
    required this.focusNodes,
    this.label = 'かんりょう',
    this.onDone,
  });

  final List<FocusNode> focusNodes;
  final String label;
  final VoidCallback? onDone;

  @override
  State<AppKeyboardDoneBar> createState() => _AppKeyboardDoneBarState();
}

class _AppKeyboardDoneBarState extends State<AppKeyboardDoneBar> {
  @override
  void initState() {
    super.initState();
    _attachListeners(widget.focusNodes);
  }

  @override
  void didUpdateWidget(covariant AppKeyboardDoneBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNodes == widget.focusNodes) return;
    _detachListeners(oldWidget.focusNodes);
    _attachListeners(widget.focusNodes);
  }

  @override
  void dispose() {
    _detachListeners(widget.focusNodes);
    super.dispose();
  }

  void _attachListeners(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.addListener(_onFocusChanged);
    }
  }

  void _detachListeners(List<FocusNode> nodes) {
    for (final node in nodes) {
      node.removeListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _hasTargetFocus {
    for (final node in widget.focusNodes) {
      if (node.hasFocus) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final isVisible = keyboardBottom > 0 && _hasTargetFocus;
    if (!isVisible) return const SizedBox.shrink();
    // Scaffold がキーボード表示時に body を縮める場合は bottom=0 が正しい。
    // 縮めない画面（resizeToAvoidBottomInset=false）ではキーボード高さ分だけ持ち上げる。
    final resizeToAvoidBottomInset =
        Scaffold.maybeOf(context)?.widget.resizeToAvoidBottomInset ?? true;
    final bottomOffset = resizeToAvoidBottomInset ? 0.0 : keyboardBottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: Material(
        color: Colors.white,
        child: Container(
          height: 44,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.listBorder)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onDone?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navSelectedIcon,
              ),
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.label,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
