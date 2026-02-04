# 友達機能（FR） 仕様書

> 坂口氏の実装を正として、友達（FR）機能の仕様をまとめたドキュメントです。
>
> 関連ドキュメント:
> - [README_DATA_STRUCTURE.md](README_DATA_STRUCTURE.md) - データ構造全体
> - [README_PROVIDERS.md](README_PROVIDERS.md) - Provider設計
> - [SCREEN_MAP.md](SCREEN_MAP.md) - 画面一覧・遷移

---

## 1. 画面一覧と遷移

### 画面一覧

| ID | 画面名 | パス | ファイル |
|----|--------|------|----------|
| FR0100 | 友達一覧 | `/fr0100` | `lib/presentation/friends/fr0100_screen.dart` |
| FR0200 | 友達詳細（チャット） | `/fr0200/:friendId` | `lib/presentation/friends/fr0200_screen.dart` |
| LB0200 | 借用書作成/編集 | `/lb0200?friendId=...` または `/lb0200/:loanId` | `lib/presentation/loan_book/lb0200_screen.dart` |

### 画面遷移図

```
┌──────────────────────────────────────────────────────────────┐
│                    TO0100 (ホーム)                            │
│                         │                                    │
│              友だちカード または BottomNav                     │
│                         │                                    │
│                         ▼                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              FR0100 友達一覧                            │  │
│  │  - 友達カード一覧（検索可能）                           │  │
│  │  - FAB「＋ともだちをついか」                            │  │
│  │                         │                              │  │
│  │              友達カード タップ                          │  │
│  │                         ▼                              │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │           FR0200 友達詳細                         │  │  │
│  │  │  - チャット風タイムライン                          │  │  │
│  │  │  - 借用書バブル + メッセージバブル                 │  │  │
│  │  │  - 入力バー（書類アイコン / テキスト / 送信）      │  │  │
│  │  │  - みかえしチップ                                 │  │  │
│  │  │                         │                         │  │  │
│  │  │         ┌───────────────┼───────────────┐         │  │  │
│  │  │         ▼               ▼               ▼         │  │  │
│  │  │    LB0200          操作シート       みかえし       │  │  │
│  │  │   (借用書作成)    (詳細/返済/承認)   一覧シート     │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### 遷移ルール

| From | To | トリガー |
|------|----|----------|
| TO0100 | FR0100 | BottomNav「ともだち」/ 友だちカード「すべて見る」 |
| FR0100 | FR0200 | 友達カード タップ |
| FR0200 | LB0200 | 入力バーの書類アイコン タップ（`?friendId=...`） |
| FR0200 | LB0200 | 借用書バブル → 操作シート →「しょうさいをみる」 |
| FR0200 | FR0100 | 戻るボタン / スワイプバック |

---

## 2. 画面ごとの機能概要

### FR0100: 友達一覧

**役割**: 友達（Friend）を一覧表示し、検索・追加が可能

**主要機能**:
- **友達一覧表示**: `friendSummariesProvider` から取得
- **検索フィルタ**: 表示名で部分一致検索
- **友達追加**: ダイアログでユーザーID/名前を入力 → `friendActionsProvider.addFriend()`
- **貸借サマリー表示**: 各友達ごとの「かした/かりた」残額合計と最も近い返済期限

**UI構成**:
```
AppBar: 「ともだち」
├── 検索バー (CupertinoSearchTextField)
├── 友達カードリスト
│   └── _FriendCard
│       ├── 表示名
│       ├── かした：¥X / かりた：¥X
│       └── めやすのひ：YYYY/MM/DD
├── FAB: 「＋ ともだち を ついか」
└── CommonBottomNavBar
```

---

### FR0200: 友達詳細（チャット）

**役割**: 特定の友達との貸借履歴をチャット風タイムラインで表示

**主要機能**:
1. **チャットタイムライン**: 借用書とメッセージを時系列で表示
2. **借用書バブル**: 金額、ステータス、返済状況を表示
3. **メッセージ入力**: テキストメッセージの送信（Hive永続化）
4. **借用書作成**: 入力欄の書類アイコン → LB0200へ遷移
5. **みかえしチップ**: 未返済の「かりた」借用書の合計を表示
6. **借用書操作シート**: タップで詳細表示・返済・承認/却下

**UI構成**:
```
AppBar: {友達の表示名}
├── タイムライン (SingleChildScrollView)
│   ├── _DateChip（日付区切り）
│   ├── _TxBubble（借用書）
│   │   ├── ヘッダー: かした/かりた + ステータスバッジ
│   │   ├── 金額
│   │   ├── 用途
│   │   ├── 返済状況
│   │   └── めやすのひ
│   └── _ChatBubble（メッセージ）
├── みかえしチップ（Positioned）
│   └── 未返済の「かりた」件数と合計金額
└── 入力バー
    ├── 借用書追加ボタン（書類アイコン）
    ├── CupertinoTextField
    └── 送信ボタン
```

**左右表示ルール（LINE風）**:
- **メッセージ**: `senderId == currentUserId` は右、相手は左
- **借用書**: `createdBy == currentUserId` は右、相手は左
  - 既存データで `createdBy` が空の場合は、後方互換として `direction == lent` を右に表示

**操作シート（借用書タップ時）**:
- 金額・用途・返済期限を表示
- 「かえす」ボタン（自分が借りた場合）
- 「しょうにん/きょひ」ボタン（自分が貸した + pending の場合）
- 「しょうさい を みる」→ LB0200へ遷移

---

## 3. モデル（Model）

### Loan（借用書）

**ファイル**: `lib/domain/models/loan_model.dart`

```dart
class Loan {
  final String id;
  final LoanDirection direction;     // lent (かした) / borrowed (かりた)
  final String counterpartyId;       // 相手のユーザーID
  final String createdBy;            // 作成者（送信者）のユーザーID
  final int amountYen;               // 元金
  final String purpose;              // 用途
  final DateTime dueDate;            // 返済期限
  final LoanStatus status;           // pending/approved/rejected
  final DateTime createdAt;          // 作成日
  final DateTime? deletedAt;         // 論理削除日時
  final String iouNo;                // 借用書番号
  final List<Repayment> repayments;  // 返済履歴

  // 計算プロパティ
  int get repaidYen;      // 返済合計
  int get remainingYen;   // 残額
  bool get isRepaid;      // 完済判定
}

class Repayment {
  final int amountYen;
  final DateTime paidAt;
}
```

### LoanDirection（貸借の向き）

```dart
enum LoanDirection { 
  lent,      // かした（自分→相手）
  borrowed   // かりた（相手→自分）
}
```

### LoanStatus（申請ステータス）

```dart
enum LoanStatus { 
  pending,   // しんせいちゅう
  approved,  // しょうにんずみ
  rejected   // きょひ
}
```

**ステータス遷移**:
```
[借りた側が作成]
     │
     ▼
  pending (しんせいちゅう)
     │
  ┌──┴──┐
  ▼     ▼
approved  rejected
(しょうにんずみ) (きょひ)
```

**ステータスバッジの色**:

| Status | ラベル | 背景色 | テキスト色 |
|--------|--------|--------|------------|
| pending | しんせいちゅう | `#FEF3C7` | `#D97706` |
| approved | しょうにんずみ | `#DCFCE7` | `#059669` |
| rejected | きょひ | `#FEE2E2` | `#DC2626` |

---

### Friend（友達）

**ファイル**: `lib/domain/models/friend_model.dart`

```dart
class Friend {
  final String userId;       // ユーザーID（counterpartyIdと紐づく）
  final DateTime createdAt;  // 友達登録日時
  final DateTime? deletedAt; // 論理削除日時
}
```

---

### ChatMessage（チャットメッセージ）

**ファイル**: `lib/domain/models/chat_message_model.dart`

```dart
class ChatMessage {
  final String id;
  final String threadId;     // 1対1の場合は friendId と同値
  final String senderId;     // 送信者のユーザーID
  final String text;
  final DateTime createdAt;
  final DateTime? deletedAt; // 論理削除
}
```

---

### User（ユーザー）

**ファイル**: `lib/domain/models/user_model.dart`

```dart
class User {
  final String id;
  final String displayName;    // 表示名
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? deletedAt;
}
```

---

## 4. リポジトリ（Repository）

### LoanRepository

**インターフェース**: `lib/domain/repositories/loan_repository.dart`
**実装**: `lib/infrastructure/repositories/hive_loan_repository.dart`

| メソッド | 責務 |
|----------|------|
| `getAll()` | 全借用書を取得（論理削除除く） |
| `getById(id)` | ID指定で1件取得 |
| `getByCounterparty(counterpartyId)` | 相手ID指定でフィルタ取得 |
| `upsert(loan)` | 新規/更新 |
| `delete(id)` | 論理削除 |
| `calcTotals()` | 全体の貸借残額合計を計算 |
| `newId()` | 新規ID生成（timestamp） |

---

### FriendRepository

**インターフェース**: `lib/domain/repositories/friend_repository.dart`
**実装**: `lib/infrastructure/repositories/hive_friend_repository.dart`

| メソッド | 責務 |
|----------|------|
| `getAll()` | 論理削除されていない全友達を取得 |
| `add(userId)` | 友達を追加（既存削除済みは復活） |
| `remove(userId)` | 友達を論理削除 |
| `search(query)` | userIdで部分一致検索 |

---

### ChatMessageRepository

**インターフェース**: `lib/domain/repositories/chat_message_repository.dart`
**実装**: `lib/infrastructure/repositories/hive_chat_message_repository.dart`

| メソッド | 責務 |
|----------|------|
| `getAll()` | 全メッセージを取得（論理削除除く） |
| `getByThreadId(threadId)` | threadId（= friendId）で絞り込み |
| `getById(id)` | ID指定で1件取得 |
| `upsert(message)` | 新規/更新 |
| `delete(id)` | 論理削除 |
| `newId()` | 新規ID生成 |

---

## 5. Provider

**ファイル**: `lib/application/providers/loan_providers.dart`, `lib/application/providers/chat_message_providers.dart`

### Repository Providers

| Provider | 返り値 |
|----------|--------|
| `loanRepositoryProvider` | `LoanRepository` |
| `friendRepositoryProvider` | `FriendRepository` |
| `userRepositoryProvider` | `UserRepository` |
| `chatMessageRepositoryProvider` | `ChatMessageRepository` |

### Data Providers

| Provider | 種別 | 責務 | 使用画面 |
|----------|------|------|----------|
| `allLoansProvider` | `FutureProvider` | 全Loan一覧 | - |
| `loansByCounterpartyProvider(friendId)` | `FutureProvider.family` | 相手別Loan一覧 | FR0200 |
| `allFriendsProvider` | `FutureProvider` | 全Friend一覧 | - |
| `friendSummariesProvider` | `FutureProvider` | 友達サマリー（残額・期限） | FR0100 |
| `messagesByThreadProvider(threadId)` | `Provider.family` | スレッド別メッセージ | FR0200 |

### Action Providers（書き込み用）

| Provider | 主なメソッド |
|----------|--------------|
| `loanActionsProvider` | `createLoan()`, `addRepayment()`, `approveLoan()`, `rejectLoan()` |
| `friendActionsProvider` | `addFriend()`, `removeFriend()` |
| `chatMessageActionsProvider` | `sendMessage()`, `deleteMessage()` |

---

## 6. FR0200でのチャット・借用書の保存方法

### メッセージの保存

**保存先**: Hive `messages` Box（Map保存）

**フロー**:
1. ユーザーがテキスト入力 → 送信ボタン
2. `chatMessageActionsProvider.sendMessage()` を呼び出し
3. `ChatMessage` を生成し Hive に永続化
4. `messagesByThreadProvider` が更新され画面に反映

```dart
// FR0200での送信処理
void _handleSend() {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;
  ref.read(chatMessageActionsProvider.notifier).sendMessage(
    threadId: widget.friendId,
    senderId: currentUserId,
    text: text,
  );
  _messageController.clear();
}
```

### 借用書の保存

**保存先**: Hive `loans` Box（Map保存）

**フロー**:
1. 入力バーの書類アイコン → LB0200 へ遷移
2. LB0200 で金額・用途・期限を入力
3. `loanActionsProvider.createLoan()` を呼び出し
4. `Loan` を生成し Hive に永続化
5. FR0200 に戻ると `loansByCounterpartyProvider` が更新され表示

### タイムラインの構築

FR0200では借用書とメッセージを統合して時系列表示:

```dart
Widget _buildTimeline(List<Loan> loans, List<ChatMessage> messages) {
  final items = <({DateTime t, bool isLoan, Loan? loan, ChatMessage? msg})>[];

  for (final l in loans) {
    items.add((t: l.createdAt, isLoan: true, loan: l, msg: null));
  }
  for (final m in messages) {
    items.add((t: m.createdAt, isLoan: false, loan: null, msg: m));
  }

  items.sort((a, b) => a.t.compareTo(b.t)); // 古い→新しい
  // ...
}
```

---

## 7. データフロー図

```
┌─────────────────────────────────────────────────────────────────┐
│                         Mock データ                             │
│  users_mock.dart    threads_mock.dart    loans_mock.dart        │
│  contacts_mock.dart fr_chat_messages_mock.dart                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (初回シード)
┌─────────────────────────────────────────────────────────────────┐
│                     Hive Box（永続化層）                         │
│  users     threads     friends     loans     messages           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Infrastructure (Repository実装)                 │
│  HiveUserRepository   HiveFriendRepository   HiveLoanRepository │
│  HiveThreadRepository HiveChatMessageRepository                 │
└─────────────────────────────────────────────────────────────────┘
                              │ implements
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Domain (Repository Interface)                 │
│  UserRepository   FriendRepository   LoanRepository             │
│  ThreadRepository ChatMessageRepository                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application (Providers)                       │
│  loan_providers.dart                                            │
│    ├── friendSummariesProvider ← FR0100                         │
│    ├── loansByCounterpartyProvider(friendId) ← FR0200           │
│    └── loanActionsProvider                                      │
│                                                                  │
│  chat_message_providers.dart                                    │
│    ├── messagesByThreadProvider(threadId) ← FR0200              │
│    └── chatMessageActionsProvider                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation (画面)                           │
│  FR0100: ref.watch(friendSummariesProvider)                     │
│  FR0200: ref.watch(loansByCounterpartyProvider(friendId))       │
│          ref.watch(messagesByThreadProvider(friendId))          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. 現在のユーザーID

```dart
const String currentUserId = 'u_001';  // users_mock.dart で定義
```

---

## 更新履歴

| 日付 | 内容 |
|------|------|
| 2026/02/04 | 初版作成（坂口実装ベース）、ChatMessage永続化対応 |
