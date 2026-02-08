# エラー設計（AppError）

このドキュメントは「しゃくよーしょ」アプリにおける **エラー設計の共通ルール**をまとめたものです。

UI / Provider / Repository のどこでエラーが発生しても  
**必ず AppError に集約して扱う**ことを目的とします。

Firebase 導入後も、UI 側の実装を変えずに済む設計を前提とします。

---

## 目的

- エラー表示・遷移・ログのルールを統一する
- 画面ごとにバラバラな try-catch をなくす
- Firebase 移行後も同じエラー設計を維持する
- 将来エラーパターンが増えても修正箇所を最小化する

---

## 設計方針（重要）

### 基本原則

1. **例外は UI まで持ち上げない**
2. **Repository で AppError に変換する**
3. **UI は AppError の type だけを見る**
4. 文言・遷移は **中央定義**から決める

---

## AppError の設計

### AppErrorType（分類）

```dart
enum AppErrorType {
  network,        // 通信できない / タイムアウト
  notFound,       // データが存在しない
  invalid,        // 入力値・状態が不正（画面固有）
  unauthorized,   // 認証・権限（将来用）
  unknown,        // 想定外エラー
}
```

### AppError 本体

```dart
class AppError implements Exception {
  final AppErrorType type;
  final String userMessage; // UI表示用（必須）
  final String? message;    // ログ用
  final Object? cause;
  final StackTrace? stackTrace;

  const AppError({
    required this.type,
    required this.userMessage,
    this.message,
    this.cause,
    this.stackTrace,
  });
}
```

---

## エラー種別ごとの UI ルール

| type | 文言 | OK押下時の挙動 |
|---|---|---|
| network | つうしんえらーがはっせいしました | ホームへ戻る |
| notFound | データがそんざいしません | ホームへ戻る |
| invalid | 画面固有の文言 | その場に留まる |
| unauthorized | （将来用） | コメントアウト |
| unknown | よきせぬエラーがはっせいしました | 再起動 → スプラッシュ |

※ 再試行ボタンの文言は **「もういちど」** に統一する。

---

## 表示方法の統一

- **操作を止めるエラー**：Dialog（共通ダイアログ）
- **軽微な失敗**：SnackBar（最小限）
- **画面が成立しない**：ErrorView（将来対応）
- **ローディング**：共通ローディングを使う（画面/操作で統一）

文言は固定しない。  
**type × 画面文脈で userMessage を渡す。**

### ローディングの基本ルール

- 画面取得中は **共通ローディングUI** に統一する
- 操作中は **ボタンを無効化** し、二重送信を防ぐ
- ローディング中にエラーが出た場合は **AppError に変換して表示**

---

## Repository の責務（最重要）

Repository は **例外を直接 throw しない**。

### 例：Firebase 対応を見据えた変換

```dart
try {
  final doc = await firestore.doc(path).get();
  if (!doc.exists) {
    throw const AppError(
      type: AppErrorType.notFound,
      userMessage: 'データが そんざいしません',
    );
  }
} on FirebaseException catch (e, st) {
  throw AppError(
    type: AppErrorType.network,
    userMessage: 'つうしんえらーが はっせいしました',
    message: e.message,
    cause: e,
    stackTrace: st,
  );
} catch (e, st) {
  throw AppError(
    type: AppErrorType.unknown,
    userMessage: 'よきせぬエラーが はっせいしました',
    cause: e,
    stackTrace: st,
  );
}
```

👉 FirebaseException / PlatformException の変換責務は **必ず Repository に置く**。

---

## Provider / UseCase の扱い

- AppError を **加工せずそのまま返す**
- try-catch で握りつぶさない

```dart
Future<void> load() async {
  try {
    await repo.fetch();
  } on AppError {
    rethrow;
  }
}
```

---

## UI（Presentation）の扱い

UI は **AppErrorType だけ**を見て挙動を決める。

```dart
void showError(BuildContext context, AppError error) {
  showAppErrorDialog(
    context: context,
    error: error,
  );
}
```

---

## ログ設計（最小コスト）

- `userMessage`：UI専用（ログに出さない）
- `message / cause / stackTrace`：ログ用
- AppLogger に集約

```dart
AppLogger.error(
  type: error.type,
  message: error.message,
  cause: error.cause,
);
```

---

## Firebase 移行時の影響範囲

| 層 | 変更 |
|---|---|
| Repository | FirebaseException → AppError 変換を追加 |
| Provider | 変更なし |
| UI | 変更なし |
| Dialog | 変更なし |

---

## 今後やること（TODO）

- AppError 実装ファイル作成
- 共通エラーダイアログコンポーネント化
- 共通ローディングコンポーネント化
- AppErrorMapper（例外→AppError）の共通化

---

## まとめ

**AppError を境界にして、  
「例外の世界」と「UIの世界」を完全に分離する。**
