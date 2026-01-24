# アーキテクチャ / レイヤー構成

このプロジェクトは **Flutter + Riverpod + go_router** を前提に、
「UI（Presentation）→ ユースケース（Application）→ 契約（Domain）→ 実装（Infrastructure）」の依存方向を保つことで、
将来の **Firebase 等の外部I/O差し替え** に強い構成を目指します。

---

## 目的

- 画面（UI）から外部I/O（将来のFirebase/REST等）を直接触らせない
- ビジネスロジックをUIから分離し、テストしやすくする
- Mock → Firebase など実装の差し替えを Provider で完結させる

---

## ディレクトリ構成（概要）

```
lib/
  application/                 # 状態管理・ユースケース（アプリケーション層）
    providers/
    usecases/

  domain/                      # モデル・契約・計算（ドメイン層）
    models/
    repositories/
    services/

  infrastructure/              # 外部I/Oの詳細（実装）
    repositories/
    mock/

  data/                        # fixture/seed（生データのみ）
    mock/

  presentation/                # UI
  router/                      # go_router
  core/                        # 汎用ユーティリティ（ログ、拡張等）
```

---

## 各層の責務

### presentation/
- Widget/UI
- ユーザー入力を受け取り、Provider/UseCase を呼ぶ
- **ビジネスルール（計算・整合性）を持たない**

### application/
- Riverpod Provider（状態の公開・更新）
- UseCase（「1つの操作」を実行するオーケストレーション）
  - 例: グループ作成（Thread作成 + EventMeta作成）
- Repository（Domainの契約）を受け取り、実装には依存しない

### domain/
- models/: アプリの中心となるデータ構造
- repositories/: Repositoryの契約（interface）
- services/: **純粋なビジネスロジック**（計算・ルール）
  - 例: `BalanceCalculator`（残高計算）
- **外部I/O（Firebase/HTTP/DB）に依存しない**

### infrastructure/
- repositories/: DomainのRepository契約を実装する
  - 例: `MockTransactionRepository`
  - 将来: `FirebaseTransactionRepository` など
- mock/: Mock実装専用のヘルパー
  - DTO→Domain 変換（mapper）
  - fixtureの整合性チェック（validator）

### data/
- mock/: **純データ（fixture/seed）だけ**
  - 例: `users_mock.dart`, `event_transactions_mock.dart`
- 原則として **import しない**（依存を作らない）

### core/
- アプリ全体で横断的に使うユーティリティ
  - 例: logger、extensions
- Mock専用ロジックは置かない（置くなら別の場所へ）

---

## 依存ルール（壊れにくくする3ルール）

1. `domain/services` は `domain/models` のみ参照してよい
2. `infrastructure/*` は `domain` を参照してよい（モデル/契約）
3. `data/mock` は **何も参照しない**（純データ）

この3ルールを守れば、層の境界がブレにくくなります。

---

## 命名ルール（推奨）

### Mapper
- 目的が「DTO → Domain 変換」であることが分かる名前にする
- Mock専用であることもファイル名に含める

例:
- `infrastructure/mock/mock_transaction_mapper.dart`
- （将来）`infrastructure/firebase/firebase_transaction_mapper.dart`

### Validator
- fixtureの整合性チェック用（デバッグ用途が多い）

例:
- `infrastructure/mock/mock_transaction_validator.dart`

---

## Providerでの差し替えイメージ

- `application/providers` は `domain/repositories` の型だけを知る
- 実体は Provider で切り替える（Mock ⇄ Firebase）

```dart
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return MockTransactionRepository(initial: /* ... */);
  // 将来: return FirebaseTransactionRepository(/* ... */);
});
```

---

## 関連ドキュメント

- `docs/README_PROVIDERS.md`（Provider設計）
- `docs/README_DATA_STRUCTURE.md`（データ構造）
- `docs/SCREEN_MAP.md`（画面一覧/遷移）
