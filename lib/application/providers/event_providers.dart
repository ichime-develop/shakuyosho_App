import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shakuyousho_app/data/mock/event_meta_mock.dart'
    as event_meta_mock;
import 'package:shakuyousho_app/data/mock/threads_mock.dart' as threads_mock;
import 'package:shakuyousho_app/infrastructure/mock/mock_transaction_mapper.dart'
    as mock_transaction_mapper;
import 'package:shakuyousho_app/infrastructure/repositories/hive_event_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/hive_transaction_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/hive_thread_repository.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/domain/repositories/thread_repository.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';

// User関連Providerはuser_providers.dartに集約（再エクスポート）
export 'package:shakuyousho_app/application/providers/user_providers.dart';

class EventDetail {
  const EventDetail({required this.meta, required this.transactions});
  final EventMeta meta;
  final List<Transaction> transactions;
}

class EventDerivedSummary {
  const EventDerivedSummary({
    required this.participantIds,
    required this.lastUpdatedAt,
    required this.isSettled,
  });

  final List<String> participantIds;
  final DateTime lastUpdatedAt;
  final bool isSettled;
}

class EventMetaListNotifier extends StateNotifier<List<EventMeta>>
    implements EventRepository {
  EventMetaListNotifier({
    required EventRepository eventRepository,
    required List<EventMeta> initialMetas,
  }) : _eventRepository = eventRepository,
       super(List<EventMeta>.from(initialMetas));

  final EventRepository _eventRepository;

  @override
  List<EventMeta> getAllEventMetas() =>
      List.unmodifiable(state.where((m) => m.deletedAt == null));

  @override
  EventMeta? getEventMetaById(String eventId) {
    for (final meta in state) {
      if (meta.id == eventId && meta.deletedAt == null) return meta;
    }
    return null;
  }

  @override
  void upsertEventMeta(EventMeta meta) {
    _eventRepository.upsertEventMeta(meta);
    final updated = [...state];
    final index = updated.indexWhere((m) => m.id == meta.id);
    if (index == -1) {
      updated.add(meta);
    } else {
      updated[index] = meta;
    }
    state = updated;
  }

  @override
  void deleteEventMeta(String eventId) {
    _eventRepository.deleteEventMeta(eventId);
    final now = DateTime.now();
    state = state
        .map((meta) {
          if (meta.id != eventId) return meta;
          return meta.copyWith(deletedAt: now, updatedAt: now);
        })
        .toList(growable: false);
  }
}

class TransactionListNotifier extends StateNotifier<List<Transaction>>
    implements TransactionRepository {
  TransactionListNotifier({
    required TransactionRepository transactionRepository,
    required EventRepository eventRepository,
    required List<Transaction> initialTransactions,
  }) : _transactionRepository = transactionRepository,
       _eventRepository = eventRepository,
       super(List<Transaction>.from(initialTransactions));

  final TransactionRepository _transactionRepository;
  final EventRepository _eventRepository;

  @override
  List<Transaction> getByEventId(String eventId) {
    return _transactionRepository.getByEventId(eventId);
  }

  @override
  void upsert(Transaction tx) {
    _transactionRepository.upsert(tx);
    final updated = [...state];
    final index = updated.indexWhere((t) => t.id == tx.id);
    if (index == -1) {
      updated.add(tx);
    } else {
      updated[index] = tx;
    }
    state = updated;
    _markEventInProgressIfSettled(tx.eventId);
  }

  @override
  void delete(String txId) {
    final eventId = _findEventId(txId);
    _transactionRepository.delete(txId);
    final now = DateTime.now();
    final updated = state
        .map((t) {
          if (t.id != txId) return t;
          return t.copyWith(deletedAt: now, updatedAt: now);
        })
        .toList(growable: false);
    state = updated;
    _markEventInProgressIfSettled(eventId);
  }

  String? _findEventId(String txId) {
    for (final tx in state) {
      if (tx.id == txId) return tx.eventId;
    }
    return null;
  }

  void _markEventInProgressIfSettled(String? eventId) {
    if (eventId == null || eventId.isEmpty) return;
    final meta = _eventRepository.getEventMetaById(eventId);
    if (meta == null) return;
    if (meta.status != EventStatus.settled) return;
    _eventRepository.upsertEventMeta(
      meta.copyWith(status: EventStatus.inProgress, updatedAt: DateTime.now()),
    );
  }
}

class ThreadListNotifier extends StateNotifier<List<Thread>>
    implements ThreadRepository {
  ThreadListNotifier({
    required ThreadRepository threadRepository,
    required List<Thread> initialThreads,
  }) : _threadRepository = threadRepository,
       super(List<Thread>.from(initialThreads));

  final ThreadRepository _threadRepository;

  @override
  List<Thread> getAll() =>
      List.unmodifiable(state.where((t) => t.deletedAt == null));

  @override
  Thread? getById(String threadId) {
    for (final thread in state) {
      if (thread.id == threadId && thread.deletedAt == null) return thread;
    }
    return null;
  }

  @override
  void upsert(Thread thread) {
    _threadRepository.upsert(thread);
    final updated = [...state];
    final index = updated.indexWhere((t) => t.id == thread.id);
    if (index == -1) {
      updated.add(thread);
    } else {
      updated[index] = thread;
    }
    state = updated;
  }
}

// UserListNotifier は user_providers.dart に移動済み

// モックデータ（初回投入用）
final List<EventMeta> _mockEventMetas = List<EventMeta>.from(
  event_meta_mock.mockEventMetas,
);
// 取引モックの初期化（UI/集計の動作確認用）
final List<Transaction> _mockTransactions = List<Transaction>.from(
  mock_transaction_mapper.mockDomainTransactions,
);
// スレッドモックの初期化（会話/グループ用）
final List<Thread> _mockThreads = List<Thread>.from(threads_mock.mockThreads);
void _seedEventMetasIfEmpty(Box<Map> box) {
  if (box.isNotEmpty) return;
  for (final meta in _mockEventMetas) {
    box.put(meta.id, meta.toMap());
  }
}

void _seedTransactionsIfEmpty(Box<Map> box) {
  if (box.isNotEmpty) return;
  for (final tx in _mockTransactions) {
    box.put(tx.id, tx.toMap());
  }
}

void _seedThreadsIfEmpty(Box<Map> box) {
  if (box.isNotEmpty) return;
  for (final thread in _mockThreads) {
    box.put(thread.id, thread.toMap());
  }
}

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

// リポジトリの実体（Map保存）
// Providerからはインターフェース(EventRepository等)として扱う
final Box<Map> _eventMetaBox = Hive.box<Map>('eventMetas');
final EventRepository _eventRepo = HiveEventRepository(
  eventMetaBox: _eventMetaBox,
);
final List<EventMeta> _initialEventMetas = (() {
  _seedEventMetasIfEmpty(_eventMetaBox);
  return _eventMetaBox.values
      .map((raw) => EventMeta.fromMap(_castMap(raw)))
      .toList(growable: false);
})();
final Box<Map> _transactionBox = Hive.box<Map>('transactions');
final TransactionRepository _txRepo = HiveTransactionRepository(
  transactionBox: _transactionBox,
);
final List<Transaction> _initialTransactions = (() {
  _seedTransactionsIfEmpty(_transactionBox);
  return _transactionBox.values
      .map((raw) => Transaction.fromMap(_castMap(raw)))
      .toList(growable: false);
})();
final Box<Map> _threadBox = Hive.box<Map>('threads');
final ThreadRepository _threadRepo = HiveThreadRepository(
  threadBox: _threadBox,
);
final List<Thread> _initialThreads = (() {
  _seedThreadsIfEmpty(_threadBox);
  return _threadBox.values
      .map((raw) => Thread.fromMap(_castMap(raw)))
      .toList(growable: false);
})();
// Repository providers
// UI/ユースケース層から「保存先（Repository）」として参照するための入口。
// ここでは StateNotifier を Repository として公開しているため、
// 「読み書きの実体」は StateNotifier 側に集約される。
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return ref.read(eventMetaListProvider.notifier);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return ref.read(transactionListProvider.notifier);
});

final threadRepositoryProvider = Provider<ThreadRepository>((ref) {
  return ref.read(threadListProvider.notifier);
});

// State providers
// 画面で表示する「現在の一覧状態」を持つProvider。
// - watch: 画面が自動更新
// - notifier: 追加/更新/削除などの操作
final eventMetaListProvider =
    StateNotifierProvider<EventMetaListNotifier, List<EventMeta>>((ref) {
      return EventMetaListNotifier(
        eventRepository: _eventRepo,
        initialMetas: _initialEventMetas,
      );
    });

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, List<Transaction>>((ref) {
      return TransactionListNotifier(
        transactionRepository: _txRepo,
        eventRepository: ref.read(eventMetaListProvider.notifier),
        initialTransactions: _initialTransactions,
      );
    });

final threadListProvider =
    StateNotifierProvider<ThreadListNotifier, List<Thread>>((ref) {
      return ThreadListNotifier(
        threadRepository: _threadRepo,
        initialThreads: _initialThreads,
      );
    });

// Derived providers
// 生データを「画面で使いやすい形」に加工したProvider群。
// 例: イベントID指定のメタ取得、イベント別の取引一覧、詳細集約など。
// ここを読むと「画面が欲しいデータ」が何か分かる。
//
// eventMetaProvider
// - 役割: 指定イベントのメタを1件返す
// - フィルタ: deletedAt == null のみ
final eventMetaProvider = Provider.family<EventMeta?, String>((ref, eventId) {
  final metas = ref.watch(eventMetaListProvider);
  for (final meta in metas) {
    if (meta.id == eventId && meta.deletedAt == null) return meta;
  }
  return null;
});

// transactionsByEventProvider
// - 役割: 指定イベントに紐づく取引一覧を返す
// - フィルタ: deletedAt == null のみ
// - ソート: 日付降順（新しい取引が先頭）
final transactionsByEventProvider = Provider.family<List<Transaction>, String>((
  ref,
  eventId,
) {
  // 指定イベントに紐づく取引だけを抽出し、日付降順で返す
  final txs = ref.watch(transactionListProvider);
  final filtered = txs
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList(growable: false);
  final sorted = List<Transaction>.from(filtered)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted;
});

/// 進行中イベントを「取引があった順（最近順）」で返す
/// - 対象: deletedAt == null かつ status == inProgress
/// - 並び順: そのイベントに紐づく最新取引日時(tx.updatedAt ?? tx.date) の降順
/// - 取引が無いイベントは末尾（epoch扱い）
final inProgressEventMetasByRecentTxProvider = Provider<List<EventMeta>>((ref) {
  final metas = ref.watch(eventMetaListProvider);
  final txs = ref.watch(transactionListProvider);

  final latestTxAtByEventId = <String, DateTime>{};
  for (final tx in txs) {
    if (tx.deletedAt != null) continue;
    final eventId = tx.eventId;
    if (eventId == null || eventId.isEmpty) continue;
    final candidate = tx.updatedAt ?? tx.date;

    latestTxAtByEventId.update(
      eventId,
      (prev) => candidate.isAfter(prev) ? candidate : prev,
      ifAbsent: () => candidate,
    );
  }

  final inProgress = metas
      .where((e) => e.deletedAt == null && e.status == EventStatus.inProgress)
      .toList(growable: false);

  final epoch = DateTime.fromMillisecondsSinceEpoch(0);

  final sorted = List<EventMeta>.from(inProgress)
    ..sort((a, b) {
      final aKey = latestTxAtByEventId[a.id] ?? epoch;
      final bKey = latestTxAtByEventId[b.id] ?? epoch;
      final byTx = bKey.compareTo(aKey);
      if (byTx != 0) return byTx;
      return a.id.compareTo(b.id);
    });

  return sorted;
});

// eventDetailProvider
// - 役割: イベント詳細画面に必要な「メタ + 取引」をまとめて返す
// - 取引は新しい順に並び替え
final eventDetailProvider = Provider.family<EventDetail?, String>((
  ref,
  eventId,
) {
  // イベントメタと取引一覧をまとめた詳細情報
  final meta = ref.watch(eventMetaProvider(eventId));
  if (meta == null) return null;

  // Watch transaction state so detail updates after writes.
  ref.watch(transactionListProvider);
  final txs = List<Transaction>.from(
    ref.read(transactionRepositoryProvider).getByEventId(eventId),
  )..sort((a, b) => b.date.compareTo(a.date));
  return EventDetail(meta: meta, transactions: txs);
});

// settlementProvider
// - 役割: 精算画面に必要な「残高・支払指示」を返す
// - 入力: eventDetailProvider から取引と参加者を取得
final settlementProvider = Provider.family<SettlementSummary?, String>((
  ref,
  eventId,
) {
  // 精算計算結果（残高・支払指示）を返す
  final detail = ref.watch(eventDetailProvider(eventId));
  if (detail == null) return null;
  return computeSettlement(
    detail.transactions,
    eventId: eventId,
    participantIds: detail.meta.participantIds,
  );
});

// deriveEventSummary
// - 役割: イベント一覧表示用のサマリーを作る
// - 入力: イベントのメタ情報 + そのイベントの取引一覧
// - 出力: 参加者一覧 / 最終更新日時 / 精算済みかどうか
EventDerivedSummary deriveEventSummary(EventMeta meta, List<Transaction> txs) {
  final participantIds = _mergeParticipantIds(meta.participantIds, txs);
  final lastUpdatedAt = _latestUpdatedAt(meta.updatedAt, txs);
  final isSettled = meta.status == EventStatus.settled;
  return EventDerivedSummary(
    participantIds: participantIds,
    lastUpdatedAt: lastUpdatedAt,
    isSettled: isSettled,
  );
}

// computeSettlement
// - 役割: 精算画面に必要な「残高」と「支払指示」を計算する
// - 入力: 取引一覧 / イベントID / 参加者一覧（任意）
// - 出力: SettlementSummary（残高 + 指示 + 生成時刻）
SettlementSummary computeSettlement(
  List<Transaction> txs, {
  required String eventId,
  List<String>? participantIds,
}) {
  final members = participantIds ?? _mergeParticipantIds(const [], txs);
  final balances = _calcNetBalances(txs, members);
  final instructions = _simplifyBalances(balances);
  return SettlementSummary(
    eventId: eventId,
    balancesByUserId: balances,
    instructions: instructions,
    generatedAt: DateTime.now(),
  );
}

// _mergeParticipantIds
// - 役割: メタの参加者 + 取引から登場したユーザーを統合して一覧化
// - 目的: 支払者/受取者がメタに居ないケースも一覧に含める
List<String> _mergeParticipantIds(List<String> base, List<Transaction> txs) {
  final ids = <String>{...base};
  for (final tx in txs) {
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      if (paidBy != null) ids.add(paidBy);
      final shares = tx.shares;
      if (shares != null) ids.addAll(shares.keys);
    } else {
      if (tx.fromUserId != null) ids.add(tx.fromUserId!);
      if (tx.toUserId != null) ids.add(tx.toUserId!);
    }
  }
  return ids.toList(growable: false);
}

// _latestUpdatedAt
// - 役割: イベントの「最新更新日時」を決める
// - ルール: イベントメタ更新日時 vs 各取引の更新/作成日時の最大値
DateTime _latestUpdatedAt(DateTime metaUpdatedAt, List<Transaction> txs) {
  var latest = metaUpdatedAt;
  for (final tx in txs) {
    final candidate = tx.updatedAt ?? tx.date;
    if (candidate.isAfter(latest)) {
      latest = candidate;
    }
  }
  return latest;
}

// _calcNetBalances
// - 役割: 参加者ごとの「差額残高」を計算する
// - プラス: 受け取る側 / マイナス: 支払う側
// - expense: 支払者がプラス、参加者がマイナス
// - repayment: 返済者がプラス、受取者がマイナス
Map<String, int> _calcNetBalances(
  List<Transaction> txs,
  List<String> memberIds,
) {
  final net = {for (final id in memberIds) id: 0};
  for (final tx in txs) {
    if (tx.deletedAt != null) continue;
    if (tx.type == TxType.expense) {
      final paidBy = tx.paidBy;
      final shares = tx.shares;
      if (paidBy == null || shares == null) continue;
      net.update(
        paidBy,
        (v) => v + tx.totalAmount,
        ifAbsent: () => tx.totalAmount,
      );
      for (final entry in shares.entries) {
        net.update(
          entry.key,
          (v) => v - entry.value,
          ifAbsent: () => -entry.value,
        );
      }
    } else {
      final fromUserId = tx.fromUserId;
      final toUserId = tx.toUserId;
      if (fromUserId == null || toUserId == null) continue;
      final amount = tx.repaymentAmount ?? tx.totalAmount;
      net.update(fromUserId, (v) => v + amount, ifAbsent: () => amount);
      net.update(toUserId, (v) => v - amount, ifAbsent: () => -amount);
    }
  }
  return net;
}

// _BalanceItem
// - 役割: 精算計算用の内部データ（公開しない）
class _BalanceItem {
  _BalanceItem(this.userId, this.amount);
  final String userId;
  int amount;
}

// _simplifyBalances
// - 役割: 残高を「誰が誰にいくら払うか」に変換
// - 仕組み: プラス（受け取る側）とマイナス（支払う側）を突き合わせる
List<SettlementInstruction> _simplifyBalances(Map<String, int> balances) {
  final creditors = <_BalanceItem>[];
  final debtors = <_BalanceItem>[];
  balances.forEach((userId, amount) {
    if (amount > 0) {
      creditors.add(_BalanceItem(userId, amount));
    } else if (amount < 0) {
      debtors.add(_BalanceItem(userId, -amount));
    }
  });

  final instructions = <SettlementInstruction>[];
  int i = 0;
  int j = 0;
  while (i < debtors.length && j < creditors.length) {
    final debtor = debtors[i];
    final creditor = creditors[j];
    final pay = debtor.amount < creditor.amount
        ? debtor.amount
        : creditor.amount;
    instructions.add(
      SettlementInstruction(
        fromUserId: debtor.userId,
        toUserId: creditor.userId,
        amount: pay,
        currency: 'JPY',
      ),
    );
    debtor.amount -= pay;
    creditor.amount -= pay;
    if (debtor.amount == 0) i++;
    if (creditor.amount == 0) j++;
  }
  return instructions;
}

// generateId
// - 役割: モック/一時データ用のIDを生成
// - 形式: <prefix>_YYYYMMDDhhmmssSSS + 乱数
String generateId({required String prefix}) {
  final now = DateTime.now().toUtc();
  final timestamp = now.toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
  final rand = Random().nextInt(1000).toString().padLeft(3, '0');
  return '${prefix}_$timestamp$rand';
}
