/// ダイアログ文言を「1ID＝1ダイアログ」単位で管理するための定義ファイル。
/// タイトル/本文/ボタンをIDでまとめ、画面側はID参照だけにする。
enum AppDialogButtonRole { primary, cancel, destructive }

class AppDialogButton {
  final String label;
  final AppDialogButtonRole role;

  const AppDialogButton({required this.label, required this.role});
}

class AppDialogMessage {
  final String title;
  final String message;
  final List<AppDialogButton> buttons;

  const AppDialogMessage({
    required this.title,
    required this.message,
    required this.buttons,
  });
}

class AppMessageId {
  const AppMessageId._();

  // 共通（画面に紐づかない）
  static const s001 = 'S001'; // network
  static const s002 = 'S002'; // notFound
  static const s003 = 'S003'; // unknown

  // EV0200
  static const ev0200_001 = 'ev0200_001';

  // TR0100
  static const tr0100_001 = 'tr0100_001';

  // LB0200
  static const lb0200_001 = 'lb0200_001';

  // FR0200
  static const fr0200_001 = 'fr0200_001';
}

class AppMessages {
  const AppMessages._();

  static const Map<String, AppDialogMessage> _dialogs = {
    // 共通
    AppMessageId.s001: AppDialogMessage(
      title: 'えらー',
      message: 'つうしんえらーが はっせいしました',
      buttons: [
        AppDialogButton(label: 'OK', role: AppDialogButtonRole.primary),
      ],
    ),
    AppMessageId.s002: AppDialogMessage(
      title: 'えらー',
      message: 'データが そんざいしません',
      buttons: [
        AppDialogButton(label: 'OK', role: AppDialogButtonRole.primary),
      ],
    ),
    AppMessageId.s003: AppDialogMessage(
      title: 'えらー',
      message: 'よきせぬエラーが はっせいしました',
      buttons: [
        AppDialogButton(label: 'OK', role: AppDialogButtonRole.primary),
      ],
    ),

    // EV0200
    AppMessageId.ev0200_001: AppDialogMessage(
      title: 'イベントをけす',
      message: 'このイベントをけしていい？\n'
          'メモしたおしはらいももとにもどらないよ。',
      buttons: [
        AppDialogButton(label: 'キャンセル', role: AppDialogButtonRole.cancel),
        AppDialogButton(
          label: 'さくじょ',
          role: AppDialogButtonRole.destructive,
        ),
      ],
    ),

    // TR0100
    AppMessageId.tr0100_001: AppDialogMessage(
      title: 'おしはらいをけす',
      message: 'このおしはらいをけしていい？\n'
          'もとにもどせないよ。',
      buttons: [
        AppDialogButton(label: 'キャンセル', role: AppDialogButtonRole.cancel),
        AppDialogButton(
          label: 'さくじょ',
          role: AppDialogButtonRole.destructive,
        ),
      ],
    ),

    // LB0200
    AppMessageId.lb0200_001: AppDialogMessage(
      title: 'さくじょ',
      message: 'この とりひき を けしますか？',
      buttons: [
        AppDialogButton(label: 'やめる', role: AppDialogButtonRole.cancel),
        AppDialogButton(
          label: 'さくじょ',
          role: AppDialogButtonRole.destructive,
        ),
      ],
    ),

    // FR0200
    AppMessageId.fr0200_001: AppDialogMessage(
      title: 'さくじょ',
      message: 'この しゃくようしょ を けしますか？',
      buttons: [
        AppDialogButton(label: 'やめる', role: AppDialogButtonRole.cancel),
        AppDialogButton(
          label: 'さくじょ',
          role: AppDialogButtonRole.destructive,
        ),
      ],
    ),
  };

  static AppDialogMessage dialog(String id) {
    final msg = _dialogs[id];
    if (msg != null) return msg;
    return const AppDialogMessage(
      title: 'えらー',
      message: 'よきせぬエラーが はっせいしました',
      buttons: [
        AppDialogButton(label: 'OK', role: AppDialogButtonRole.primary),
      ],
    );
  }

  @Deprecated('Use AppMessages.dialog instead.')
  static String text(String id) => dialog(id).message;
}
