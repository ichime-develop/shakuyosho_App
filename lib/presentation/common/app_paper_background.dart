import 'package:flutter/material.dart';

class AppPaperBackground extends StatelessWidget {
  const AppPaperBackground({
    super.key,
    required this.child,
    this.opacity = 0.03,
  });

  final Widget child;

  /// 和紙テクスチャの濃さ（0.02〜0.035 推奨）。
  final double opacity;

  static const Color baseColor = Color(0xFFFFF8DC);
  static const String assetPath = 'assets/background/japanese-paper_00188.jpg';

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = opacity.clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: baseColor,
            image: DecorationImage(
              image: const AssetImage(assetPath),
              fit: BoxFit.cover,
              opacity: effectiveOpacity,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
