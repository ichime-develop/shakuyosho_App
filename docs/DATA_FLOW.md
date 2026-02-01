**データフロー（概要）**

このドキュメントは、アプリ内のデータがどのように流れるかをレイヤー毎に整理したものです。特に `EV0100`（イベント一覧）の初期表示におけるデータ取得の流れを丁寧に説明します。

- **目的**: Provider、画面（Presentation）、画面モデル、Mock データ、Repository、Infrastructure（Hive 実装）がそれぞれ何をしているかを明確にする。

**アーキテクチャ概要**

┌─────────────────────────────────────────────────────────────────────────────┐
│                          【6】Mockデータ（開発用）                           │
│   event_meta_mock.dart          event_transactions_mock.dart               │
│   mockEventMetas                mockAllTransactions                        │
│         │                              │                                   │
│         │                              ▼                                   │
│         │                   mock_transaction_mapper.dart                   │
│         │                   （MockAppTransaction → Transaction に変換）     │
│         ▼                              ▼                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                         │
                    ┌────────────────────┴────────────────────┐
                    ▼                                         ▼
┌──────────────────────────────────┐     ┌──────────────────────────────────┐
│ 【5】Infrastructure層            │     │ 【5】Infrastructure層            │
│ hive_event_repository.dart       │     │ hive_transaction_repository.dart │
│ ┌──────────────────────────────┐ │     │ ┌──────────────────────────────┐ │
│ │ HiveEventRepository          │ │     │ │ HiveTransactionRepository    │ │
│ │ - Box<EventMeta>を操作       │ │     │ │ - Box<Transaction>を操作     │ │
│ │ - getAllEventMetas()         │ │     │ │ - getByEventId()             │ │
│ │ - upsertEventMeta()          │ │     │ │ - upsert()                   │ │
│ │ - deleteEventMeta()          │ │     │ │ - delete()                   │ │
│ └──────────────────────────────┘ │     │ └──────────────────────────────┘ │
└──────────────────────────────────┘     └──────────────────────────────────┘
                    │                                         │
                    └────────────────────┬────────────────────┘
                                         │ implements
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     【4】Repository Interface（契約）                        │
│   event_repository.dart                 transaction_repository.dart         │
│   ┌───────────────────────────┐         ┌───────────────────────────────┐  │
│   │ abstract EventRepository  │         │ abstract TransactionRepository│  │
│   │ - getAllEventMetas()      │         │ - getByEventId()              │  │
│   │ - getEventMetaById()      │         │ - upsert()                    │  │
│   │ - upsertEventMeta()       │         │ - delete()                    │  │
│   │ - deleteEventMeta()       │         │                               │  │
│   └───────────────────────────┘         └───────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        【3】Provider（状態管理）                             │
│   event_providers.dart                                                      │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │ eventMetaListProvider (StateNotifierProvider)                       │  │
│   │ - 状態: List<EventMeta> を保持                                      │  │
│   │ - 内部で HiveEventRepository を使って永続化                         │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │ transactionListProvider (StateNotifierProvider)                     │  │
│   │ - 状態: List<Transaction> を保持                                    │  │
│   │ - 内部で HiveTransactionRepository を使って永続化                   │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │ transactionsByEventProvider (派生Provider)                          │  │
│   │ - transactionListProvider を watch                                  │  │
│   │ - eventId でフィルタ → 日付降順ソート                               │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        【2】Domain Model（データ構造）                       │
│                                                                             │
│   event_meta_model.dart                 transaction_model.dart              │
│   ┌───────────────────────────┐         ┌───────────────────────────────┐  │
│   │ class EventMeta           │         │ class Transaction             │  │
│   │ - id                      │         │ - id                          │  │
│   │ - title                   │         │ - eventId                     │  │
│   │ - participantIds          │         │ - type (expense/repayment)    │  │
│   │ - createdAt               │         │ - title                       │  │
│   │ - updatedAt               │         │ - totalAmount                 │  │
│   │ - deletedAt               │         │ - participantIds              │  │
│   └───────────────────────────┘         │ - paidBy, shares, ...         │  │
│                                         └───────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        【1】画面（Presentation層）                           │
│   ev0100_screen.dart                                                        │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │ Ev0100EventListScreen (ConsumerWidget)                              │  │
│   │                                                                     │  │
│   │ final metas = ref.watch(eventMetaListProvider);                     │  │
│   │   → イベント一覧を取得                                              │  │
│   │                                                                     │  │
│   │ for each meta:                                                      │  │
│   │   final txs = ref.watch(transactionsByEventProvider(meta.id));      │  │
│   │   → そのイベントの取引一覧を取得                                    │  │
│   │                                                                     │  │
│   │   final summary = deriveEventSummary(meta, txs);                    │  │
│   │   → UI用のサマリーを計算                                            │  │
│   │                                                                     │  │
│   │   _EventView(meta: meta, summary: summary)                          │  │
│   │   → 画面用モデルにまとめる                                          │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

- Presentation（画面）: UI を表示し、`ref.watch(...)` で Provider を購読する。画面はデータの所在を知らなくてよく、Provider が提供する値だけを使う。

- Application / Provider 層: 状態管理と UI に適した派生データを用意する。StateNotifier が内部状態を保持し、Repository を通じて永続化を行う。

- Domain Model: `EventMeta` や `Transaction` のようなデータ構造の定義（@HiveType による Hive 対応を含む）。

- Repository（抽象）: 「何ができるか」を定義するインターフェース（例: `EventRepository`、`TransactionRepository`）。

- Infrastructure（具象）: 実際の保存先（ここでは Hive）を扱う実装（`HiveEventRepository`、`HiveTransactionRepository`）。

- Mock データ: 開発・デモ用に用意された初期データ。初回起動時に Hive が空なら自動的にシードされる。


**各層の役割（詳説）**

- Provider（状態管理）
  - StateNotifierProvider: アプリ全体で共有する現在の一覧状態（例: `eventMetaListProvider`, `transactionListProvider`）を持つ。
  - 派生 Provider: UI がほしい形にデータを整形する（例: `transactionsByEventProvider` は eventId でフィルタして日付降順で返す）。
  - Provider は UI と Repository をつなぐ接着剤の役割。UI は `ref.watch(...)` するだけで最新状態を得られる。

- 画面（Presentation）
  - `Ev0100EventListScreen`（`lib/presentation/event/ev0100_screen.dart`）は次を行う:
    - `final metas = ref.watch(eventMetaListProvider);`
    - for each meta: `final txs = ref.watch(transactionsByEventProvider(meta.id));`
    - 取得した `EventMeta` と `List<Transaction>` を元に UI 用のサマリ（`EventDerivedSummary` 等）を計算し表示する。

- Domain Model
  - `EventMeta`（`lib/domain/models/event_meta_model.dart`）: イベントの基本情報（id, title, participantIds, createdAt, updatedAt, deletedAt）
  - `Transaction`（`lib/domain/models/transaction_model.dart`）: 取引の詳細（id, eventId, type, title, date, totalAmount, participantIds, paidBy, shares, ...）

- Repository（抽象）
  - `EventRepository`（`lib/domain/repositories/event_repository.dart`）や `TransactionRepository` は操作の契約を定義する（getAll, getById, upsert, delete など）。
  - UI / Provider 層はこれらの抽象に依存するため、実装を入れ替えやすい。

- Infrastructure（Hive 実装）
  - `HiveEventRepository`（`lib/infrastructure/repositories/hive_event_repository.dart`）や `HiveTransactionRepository`（`lib/infrastructure/repositories/hive_transaction_repository.dart`）が Box を直接操作する。
  - 例: `getByEventId` は Box の値をフィルタして返す。`upsert` は `box.put(tx.id, tx)`。

- Mock データ
  - `lib/data/mock/event_meta_mock.dart` / `lib/data/mock/event_transactions_mock.dart` に生データがあり、`lib/infrastructure/mock/mock_transaction_mapper.dart` が Mock データをドメインモデルへ変換する。
  - `event_providers.dart` 内で `_seedEventMetasIfEmpty` / `_seedTransactionsIfEmpty` が初回に Box へ投入する。


**EV0100（初期表示）の具体的な流れ（時系列）**

1. アプリ起動時に Hive の Box がオープンされる（`main.dart` 等）。
2. Provider 初期化部で `_seedEventMetasIfEmpty(_eventMetaBox)` が呼ばれる。Box が空なら `mockEventMetas` を `put` して初期化する。
3. 同様に `_seedTransactionsIfEmpty(_transactionBox)` が呼ばれ、モック取引が Hive に投入される（初回のみ）。
4. `_initialEventMetas` / `_initialTransactions` として Box の `values.toList()` が取得され、`EventMetaListNotifier` や `TransactionListNotifier` の初期状態になる。
5. `Ev0100EventListScreen` は `ref.watch(eventMetaListProvider)` でイベント一覧を取得する。
6. 画面はイベントをループし、各イベントで `ref.watch(transactionsByEventProvider(meta.id))` を呼ぶ。この派生 Provider は `transactionListProvider` を watch しており、内部で `where((t) => t.eventId == eventId && t.deletedAt == null)` と日付降順ソートを行い、UI に渡す。
7. 画面側で `deriveEventSummary(meta, txs)` のような関数を使って UI 用のサマリ（参加者一覧、最終更新日時、精算済み判定など）を計算し、`_EventView` に詰めて表示する。


**よく見るコードのスニペット（参照用）**

- イベント一覧取得（画面）:

```dart
final metas = ref.watch(eventMetaListProvider);
for (final meta in metas) {
  final txs = ref.watch(transactionsByEventProvider(meta.id));
  // UI 用にまとめる
}
```

- 派生Provider（`transactionsByEventProvider`）のロジック:

```dart
final txs = ref.watch(transactionListProvider);
final filtered = txs.where((t) => t.eventId == eventId && t.deletedAt == null).toList(growable: false);
final sorted = List<Transaction>.from(filtered)..sort((a,b) => b.date.compareTo(a.date));
return sorted;
```

- Hive 実装（抜粋）:

```dart
List<Transaction> getByEventId(String eventId) {
  return _transactionBox.values
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList(growable: false);
}

void upsert(Transaction tx) {
  _transactionBox.put(tx.id, tx);
}
```


**開発者が確認すべき主要ファイル**

- [lib/presentation/event/ev0100_screen.dart](lib/presentation/event/ev0100_screen.dart)
- [lib/application/providers/event_providers.dart](lib/application/providers/event_providers.dart)
- [lib/domain/models/event_meta_model.dart](lib/domain/models/event_meta_model.dart)
- [lib/domain/models/transaction_model.dart](lib/domain/models/transaction_model.dart)
- [lib/domain/repositories/event_repository.dart](lib/domain/repositories/event_repository.dart)
- [lib/domain/repositories/transaction_repository.dart](lib/domain/repositories/transaction_repository.dart)
- [lib/infrastructure/repositories/hive_event_repository.dart](lib/infrastructure/repositories/hive_event_repository.dart)
- [lib/infrastructure/repositories/hive_transaction_repository.dart](lib/infrastructure/repositories/hive_transaction_repository.dart)
- [lib/data/mock/event_meta_mock.dart](lib/data/mock/event_meta_mock.dart)
- [lib/data/mock/event_transactions_mock.dart](lib/data/mock/event_transactions_mock.dart)
- [lib/infrastructure/mock/mock_transaction_mapper.dart](lib/infrastructure/mock/mock_transaction_mapper.dart)


**補足 / よくある質問**

- Q: 画面はどこで永続化を意識するか？
  - A: 画面自体は永続化を知らない。Provider が Repository（StateNotifier）を通して Hive を操作するため、画面は `ref.watch` するだけでよい。

- Q: 将来データ保存先を Firebase に変えたいときは？
  - A: Repository の実装を Hive -> Firebase に差し替えればよく、UI 側の変更は不要（契約が同じである限り）。


---

このファイルを作成しました: [docs/DATA_FLOW.md](docs/DATA_FLOW.md)

次は:
- フォーマット（`dart format`）やコミットを行いますか？
- ほかに README に追加したい内容（図、ユースケース）がありますか？
