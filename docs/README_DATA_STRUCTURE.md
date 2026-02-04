# データ構造 README

> 関連ドキュメント:
> - [README_FRIENDS.md](README_FRIENDS.md) - 友達機能（FR）仕様
> - [README_PROVIDERS.md](README_PROVIDERS.md) - Provider設計
> - [SCREEN_MAP.md](SCREEN_MAP.md) - 画面一覧・遷移

## 1. 全体像（概要）
- このアプリでは以下の 4 つを一次データとする
  - User（人物マスタ）
  - Thread（会話・友達関係）
  - EventMeta（イベント・貸し借り計算の単位）
  - Transaction（支出・返済）

### 重要：Event と Thread の完全分離

Event と Thread は **完全に独立した概念** として扱う：
- Event は Thread を参照しない
- Thread は Event を参照しない
- それぞれ独立して作成・削除可能

この設計により：
- 将来の仕様変更に強い
- Firebase 移行時のデータ設計がシンプル
- 責務が明確

※ EventSummary や Settlement は保存しない派生データとする（Provider で算出）。

## 2. データツリー構造

app
├── users/{userId}
├── threads/{threadId}
├── events/{eventId}
│   └── transactions/{txId}

## 3. 各モデルの責務とフィールド

### Thread
- id
- type (group)
- title
- participantIds
- createdAt
- updatedAt
- deletedAt?: DateTime      // 論理削除
- lastActivityAt?: DateTime // 一覧ソート用

### EventMeta
- id
- title
- participantIds
- createdAt
- updatedAt
- status: 'active' | 'closed' // 進行中/完了
- memo?: string               // イベント補足
- deletedAt?: DateTime        // 論理削除

※ threadId は保持しない（Event と Thread は完全分離）

### Transaction
- id
- eventId
- title
- amount
- paidBy
- shares
- createdAt
- updatedAt
- currency: 'JPY'                  // 通貨（将来拡張前提・必須）
- type: 'expense' | 'repayment'    // 支出/返済
- memo?: string                    // 補足
- deletedAt?: DateTime             // 論理削除

## 4. ID の役割整理（重要）

| ID | 役割 |
| --- | --- |
| threadId | チャット・グループの主キー |
| eventId | イベント画面遷移・取引の主キー |
| txId | 取引の主キー |

## 5. Mock データの方針

### 一次 mock として許可されるもの
- users_mock.dart（全ユーザーDB）
- contacts_mock.dart（自分の友達リスト）
- threads_mock.dart
- event_meta_mock.dart
- event_transactions_mock.dart

### 廃止する mock
- group_mock.dart
- event_mock.dart
- events_mock.dart

### users_mock と contacts_mock の関係

```
users_mock.dart     → 全ユーザー（友達以外も含む）
contacts_mock.dart  → 自分の友達リスト（peerUserId で users を参照）
```

- FR0100/FR0200 は contacts → users の順で参照
- 表示名は `contact.nickname ?? user.displayName`
- Firebase 移行時：users コレクション + contacts サブコレクションに対応

### self の扱い（モック方針）

- `self` は User データに保存しない
- `currentUserId`（セッション/認証）から **導出** する
- 友達一覧は contacts_mock から取得し、users_mock で詳細を補完する

### Users の扱い（重要）

User は「人物マスタ」であり、
自分・友達・ゲスト・招待中の人物を区別せず **一元管理** する。

データ構造として User を分岐させず、
状態（kind / invite）によって意味を表現する。

#### User モデルの考え方

- User は常に `userId` を主キーとする
- ゲスト・招待中・正式ユーザーは **同一モデル**
- 状態遷移（ゲスト → 友達 → 自分）は「更新」で表現する

```ts
User {
  id: string
  displayName: string
  avatarUrl?: string

  // 人物の種別（UI/UX 用）
  kind: 'self' | 'friend' | 'guest'

  // 招待状態（存在する場合のみ）
  invite?: {
    status: 'pending' | 'accepted'
    invitedByUserId: string
    invitedAt: DateTime
  }

  // 認証導入後に使用（将来）
  auth?: {
    provider: 'firebase' | 'apple' | 'google'
    uid: string
  }

  createdAt: DateTime
  updatedAt: DateTime
}
```

#### 自分（self）の判定

- 「自分」は特別な User モデルではない
- `authUserId` と一致する `User.id` を **self** として扱う

#### ゲストの扱い

- ゲストも User として登録する
- 後から displayName 変更・friend 化・認証追加が可能
- ゲスト専用モデルは作らない

#### 招待（Invite）の扱い

- 招待は「人」ではなく「状態」
- InviteUser / PendingUser などの別モデルは作らない
- 招待リンクは Event / Thread 側で管理する

#### この設計のメリット

- userId が不変のため、取引・履歴の整合性が壊れない
- 認証導入・仕様変更に強い
- モデル爆発を防げる
- UI 側で柔軟な表現が可能

この方針により、
「友達とのお金のやり取りをやわらかく扱う」という
本アプリの UX 方針とも整合する。
## 6. 派生データに関する補足

- EventSummary / Settlement / Balance などの派生データは保存しない
- これらは全て Transaction からリアルタイムで再計算可能
- 設計原則として「書き込みは一次データ（Thread, EventMeta, Transaction）のみ」とする
- 派生データのキャッシュ・保存は行わず、必要に応じて都度算出する

## 7. 借用書（LB）に関する方針

### 借用書はイベント起点では発行しない

借用書（LB0100）は **個人（友だち）起点のみ** で発行・閲覧する。

- 借用書は個人の貸借履歴（FR0200 友だち詳細）から閲覧・発行する
- イベント詳細（EV0200）や清算結果（SV0100）から借用書画面へは遷移しない
- イベントの清算は SV0100 で提案・確定し、借用書は別途個人間で発行する

### 借用書データの扱い

借用書（Borrow / Iou）は **保存しない派生表示** として扱う：

- Transaction や Thread/Contact から **導出** して表示する
- 専用の Iou モデルを永続化しない
- UI 上は「借用書」として見せるが、データは Transaction の集約

### 遷移の整理

```
FR0200（友だち詳細） → LB0100（借用書）  ✅ OK
TO0100_PERSONAL     → LB0100（借用書）  ✅ OK（friendId 指定時）
EV0200（イベント詳細）→ LB0100         ❌ 遷移しない
SV0100（清算結果）   → LB0100          ❌ 遷移しない
```

この方針により、「イベント精算」と「個人の貸借管理」の責務が明確に分離される。