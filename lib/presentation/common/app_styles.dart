import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// Background
  /// アプリ全体の背景色（main.dart / AppPaperBackground）
  static const Color appBackground = Color(0xFFFFF8DC);

  @Deprecated('Use AppColors.primaryActionFill / secondaryActionBorder etc.')
  static const Color accentGreen = primaryActionFill;
  @Deprecated('Use AppColors.primaryActionFill / secondaryActionBorder etc.')
  static const Color accentGreenBorder = secondaryActionBorder;
  @Deprecated('Use AppColors.primaryActionFill / secondaryActionBorder etc.')
  static const Color accentGreenFill = secondaryActionFill;
  @Deprecated('Use AppColors.appBackground instead.')
  static const Color summaryCardBackground = appBackground;

  /// Navigation/Icon
  /// アイコンの基本色（非選択）
  static const Color iconDefault = Color(0xFF6B7280);

  /// ボトムナビの選択中アイコン色
  static const Color navSelectedIcon = Colors.black;

  /// ボトムナビの非選択アイコン色
  static const Color navUnselectedIcon = iconDefault;

  /// Amount
  /// 金額色：かした（TO0100の基準）
  static const Color lendAmount = Colors.teal;

  /// 金額色：かりた（TO0100の基準）
  static const Color borrowAmount = Colors.deepOrange;

  /// Dividers/Borders
  /// リスト区切り線（うすい線）
  static const Color dividerLight = Color(0xFFE5E7EB);

  /// リスト境界線（基本はこの色か、境界なしの2択）
  static const Color listBorder = Color(0xFFE5E7EB);

  /// ===== Action Buttons =====

  /// Primary action (e.g. 「かえす」)
  static const Color primaryActionFill = Color(0xFF6FAF92);
  static const Color primaryActionPressed = Color(0xFF5F9E83);
  static const Color primaryActionText = Colors.white;

  /// Secondary action (e.g. 「かす」)
  static const Color secondaryActionFill = Color(0xFFF3FAF6);
  static const Color secondaryActionBorder = Color(0xFFBFD8CC);
  static const Color secondaryActionText = Color(0xFF5F9E83);

  /// Add (+) action (non-green)
  static const Color addButtonBackground = Color(0xFFF3F4F6);
  static const Color addButtonBorder = Color(0xFFE0E0E0);
  static const Color addButtonIcon = Color(0xFF6B7280);

  /// ラジオボタン/チェックボックス選択時の色
  static const Color selectionActive = Colors.black;
  static const Color selectionInactive = iconDefault;
  static const Color selectionBorder = iconDefault;
  static const Color selectionCheck = Colors.white;
}

class AppRadii {
  const AppRadii._();

  /// 角丸：カード（サマリー/パネル）
  static const double card = 16;
  @Deprecated('Use AppRadii.card or AppRadii.pill depending on intent.')
  static const double button = card;

  /// 角丸：ピル（主要ボタン/フローティング）
  static const double pill = 999;

  /// 角丸：丸ボタン（+）
  static const double circle = 999;
}

class AppShadows {
  const AppShadows._();

  /// うっすら影（サマリーカード）
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color.fromARGB(20, 0, 0, 0),
      blurRadius: 15,
      offset: Offset(0, 8),
    ),
  ];

  /// 主要アクション（かえす）用の影
  static const List<BoxShadow> primaryButton = [
    BoxShadow(
      color: Color.fromARGB(30, 0, 0, 0),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// 影なし
  static const List<BoxShadow> none = [];
}

class AppTextSizes {
  const AppTextSizes._();

  /// 文字サイズ：画面タイトル（AppBar）
  static const double title = 18;

  /// 文字サイズ：セクション見出し
  static const double section = 16;

  /// 文字サイズ：本文
  static const double body = 14;

  /// 文字サイズ：補助テキスト
  static const double small = 12;

  /// 文字サイズ：最小ラベル
  static const double tiny = 11;
  /// 文字サイズ：金額（大）
  static const double amountLarge = 24;
  /// 文字サイズ：金額（特大）
  static const double amountXL = 28;
  /// 文字サイズ：金額（最大）
  static const double amountXXL = 48;
}

class AppFontWeights {
  const AppFontWeights._();

  /// 画面タイトル（AppBar）
  static const FontWeight appBarTitle = FontWeight.w700;

  /// セクション見出し
  static const FontWeight sectionTitle = FontWeight.w700;

  /// リストのタイトル
  static const FontWeight listTitle = FontWeight.w700;

  /// リストのサブタイトル
  static const FontWeight listSubtitle = FontWeight.w500;

  /// ラベル（サマリー等）
  static const FontWeight label = FontWeight.w700;
}

class AppButtonStyles {
  const AppButtonStyles._();

  /// 「かえす」など：確定アクション（緑のピル）
  static ButtonStyle get primaryPill =>
      ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryActionFill,
        foregroundColor: AppColors.primaryActionText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          AppColors.primaryActionPressed.withValues(alpha: .18),
        ),
      );

  /// 「かす」など：補助アクション（薄い枠＋淡い塗り）
  static ButtonStyle get secondaryPill => OutlinedButton.styleFrom(
    foregroundColor: AppColors.secondaryActionText,
    backgroundColor: AppColors.secondaryActionFill,
    side: const BorderSide(color: AppColors.secondaryActionBorder, width: 1.2),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: const StadiumBorder(),
  );

  /// 友達追加/イベント追加/取引追加：+ のみ（非緑）
  /// ※Widget側で `Icon(Icons.add)` を渡して使う
  static ButtonStyle get addCircle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.addButtonIcon,
    backgroundColor: AppColors.addButtonBackground,
    side: const BorderSide(color: AppColors.addButtonBorder, width: 1.2),
    padding: const EdgeInsets.all(20),
    shape: const CircleBorder(),
  ).copyWith(
    elevation: const WidgetStatePropertyAll(4),
    shadowColor: const WidgetStatePropertyAll(Color.fromARGB(60, 0, 0, 0)),
  );
}

/// チェックボックス・ラジオボタンのテーマ
class AppControlThemes {
  const AppControlThemes._();

  // 選択時：AppColors.selectionActive
  // 非選択時：白背景＋AppColors.selectionBorder の枠線
  static WidgetStateProperty<Color?> get _selectionFillWhiteInactive =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.selectionActive;
        }
        return Colors.white;
      });

  // 選択時：AppColors.selectionActive
  // 非選択時：AppColors.selectionInactive
  static WidgetStateProperty<Color?> get _selectionFill =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.selectionActive;
        }
        return AppColors.selectionInactive;
      });
      
  /// チェックボックスのテーマ
  static CheckboxThemeData get checkbox => CheckboxThemeData(
    fillColor: _selectionFillWhiteInactive,
    checkColor: WidgetStateProperty.all(AppColors.selectionCheck),
    side: const BorderSide(color: AppColors.selectionBorder, width: 1.2),
  );

  static RadioThemeData get radio => RadioThemeData(fillColor: _selectionFill);
}
