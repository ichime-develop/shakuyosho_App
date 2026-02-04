# Provider README

> 関連ドキュメント:
> - [README_FRIENDS.md](README_FRIENDS.md) - 友達機能（FR）仕様
> - [README_DATA_STRUCTURE.md](README_DATA_STRUCTURE.md) - データ構造
> - [SCREEN_MAP.md](SCREEN_MAP.md) - 画面一覧・遷移

## 1. Provider の役割分離
- Repository Provider: データの読み書きのみ
- StateNotifier / Provider: 画面用に整形・派生

## 2. Repository Providers
- threadRepositoryProvider
- eventRepositoryProvider
- transactionRepositoryProvider

## 3. State / Derived Providers 一覧

| Provider | 種別 | 責務 | 使用画面 |
| --- | --- | --- | --- |
| threadListProvider | StateNotifier | Thread一覧 | FR0100 |
| eventMetaListProvider | StateNotifier | EventMeta一覧 | EV0100 |
| eventMetaProvider(eventId) | Provider.family | EventMeta取得 | EV0200/TR0100/SV0100 |
| transactionsByEventProvider(eventId) | Provider.family | 取引一覧 | EV0200/TR0100 |
| eventDetailProvider(eventId) | Provider.family | EventMeta + Transaction | EV0200/TR0100/SV0100 |
| settlementProvider(eventId) | Provider.family | 清算計算（pure） | SV0100 |
| friendSummariesProvider | FutureProvider | 友達サマリー（残額・期限） | FR0100 |
| loansByCounterpartyProvider(friendId) | FutureProvider.family | 相手別Loan一覧 | FR0200 |
| messagesByThreadProvider(threadId) | Provider.family | スレッド別メッセージ | FR0200 |

## 4. 画面と Provider の対応表
- EV0100 -> eventMetaListProvider
- EV0200 -> eventDetailProvider
- TR0100 -> eventMetaProvider + transactionsByEventProvider
- SV0100 -> settlementProvider
- FR0100 -> friendSummariesProvider
- FR0200 -> loansByCounterpartyProvider + messagesByThreadProvider

## 5. 守るルール
- 画面は mock / repository を直接触らない
- 書き込みは必ず Repository or StateNotifier 経由
- eventId / threadId を混同しない
- 派生 Provider は副作用を持たない
