# エラーダイアログ プロンプト

（ここに記述）
# Copilot/CodeX 指示プロンプト：共通ダイアログ＋AppError＋ローディング対応

## 目的
- アプリ内のダイアログを **1つの共通コンポーネント**に統一する。
- **ボタン1つ（OKのみ）/ ボタン2つ（例：さくじょ/キャンセル）**の両方に対応する。
- destructive アクション（削除など）で **非同期処理中のローディング**を表示し、二重実行を防ぐ。
- エラーは README_ERROR_HANDLING.md に従い **AppError に集約**し、UI は AppErrorType に応じて共通ダイアログで表示する。

---

## 1. AppError を実装する（README準拠）
### 追加
- `lib/core/errors/app_error.dart`
  - `enum AppErrorType { network, notFound, invalid, unauthorized /*コメントアウトでもOK*/, unknown }`
  - `class AppError implements Exception { type, userMessage, message?, cause?, stackTrace? }`
- `lib/core/errors/app_error_mapper.dart`（最小コストでOK）
  - `AppError toAppError(Object e, StackTrace st)`：unknown 包装
  - 将来 FirebaseException/PlatformException をここで分類できる形にする（今は骨組みだけでもOK）

---

## 2. 共通ダイアログを実装する（1ボタン/2ボタン＋ローディング対応）
### 追加
- `lib/presentation/common/app_dialog.dart`

### 必須仕様
- `showAppDialog(...)` を用意
  - 引数：`title?`, `message`, `actions: List<AppDialogAction>`（1〜2個を想定、将来拡張可能）
  - `barrierDismissible` はデフォルト `true`。ただし **ローディング中は false** にする。
- `AppDialogAction`
  - `label: String`
  - `style: AppDialogActionStyle`（primary / secondary / destructive）
  - `onPressedAsync: Future<void> Function()?`（nullなら「閉じるだけ」）
  - `closeOnSuccess`（default true）
  - `closeOnFailure`（default true）

### ローディング仕様
- primary/destructive の `onPressedAsync` 実行中は
  - 全ボタン無効化
  - 押したボタン内に小さな `CircularProgressIndicator` を表示
  - 背景タップで閉じられない（barrierDismissible=false）
- `onPressedAsync` が `AppError` を throw → catch
  - 必要ならダイアログを閉じる
  - `showAppErrorDialog(...)` を表示（後述）
- `onPressedAsync` がその他例外 → unknown に包装して同様

---

## 3. 共通エラーダイアログ（AppErrorType → 挙動）
### 追加
- `lib/presentation/common/app_error_dialog.dart`

### 仕様（READMEの方針に合わせる）
- `showAppErrorDialog({required BuildContext context, required AppError error})`
- 表示文言（userMessageは画面側からも渡せる前提だが、最低限は type別のデフォルトを持つ）
  - network: 「つうしんえらーが はっせいしました」→ OK押下で **ホームへ戻る**
  - notFound: 「データが そんざいしません」→ OK押下で **ホームへ戻る**
  - invalid: **画面固有の文言**（error.userMessage を必ず使う）→ OK押下で **その場に留まる**
  - unauthorized: 将来用（コメントアウトでも可）
  - unknown: 「よきせぬエラーが はっせいしました」→ OK押下で **再起動扱い**として `/st0100` へ遷移（go_router）
- ボタンは **常に1つ（OK）**。ラベルは「OK」でよい（文言統一はしない方針だが、ここは最小コストでOK）

---

## 4. 既存の削除ダイアログ等を共通ダイアログへ置き換える
### 対象例
- FR0100 の削除確認
- EV0100 / EV0200 の削除確認
- その他「かくにん」系

### 置換後の例（2ボタン）
- `キャンセル`（secondary, onPressedAsync=null）
- `さくじょ`（destructive, onPressedAsyncで削除処理、ローディング表示）

---

## 5. ログ（最小コスト）
- `AppLogger.error(...)` に type/message/cause/stackTrace を出す（userMessageはUI専用）
- ダイアログでエラーを表示する際にも 1回ログを出す（重複は許容）

---

## Done（完了条件）
- 1ボタン/2ボタンの共通ダイアログが動作する
- destructive の非同期中にローディング表示＋二重実行防止が効く
- AppErrorType に応じた共通エラーダイアログが出て、指定の遷移が行われる
- 既存の削除ダイアログが共通ダイアログへ置換される
