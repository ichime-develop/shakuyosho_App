import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/data/mock/event_meta_mock.dart'
    as event_meta_mock;
import 'package:shakuyousho_app/data/mock/event_mock.dart' as event_mock;
import 'package:shakuyousho_app/data/mock/transactions_mock.dart'
    as transactions_mock;
import 'package:shakuyousho_app/data/repository/event_repository.dart';
import 'package:shakuyousho_app/data/repository/transaction_repository.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';

class EventState {
  EventState({required this.metas, required this.transactions});

  final List<EventMeta> metas;
  final List<Transaction> transactions;

  EventState copyWith({
    List<EventMeta>? metas,
    List<Transaction>? transactions,
  }) {
    return EventState(
      metas: metas ?? this.metas,
      transactions: transactions ?? this.transactions,
    );
  }
}

class EventStateNotifier extends StateNotifier<EventState> {
  EventStateNotifier({
    required EventRepository eventRepository,
    required TransactionRepository transactionRepository,
  })  : _eventRepository = eventRepository,
        _transactionRepository = transactionRepository,
        super(
          EventState(
            metas: eventRepository.getAllEventMetas(),
            transactions: transactionRepository.getAllTransactions(),
          ),
        );

  final EventRepository _eventRepository;
  final TransactionRepository _transactionRepository;

  Future<void> load() async {
    final metas = _eventRepository.getAllEventMetas();
    final txs = _transactionRepository.getAllTransactions();
    state = state.copyWith(metas: metas, transactions: txs);
  }

  Future<void> upsertEventMeta(EventMeta meta) async {
    _eventRepository.upsertEventMeta(meta);
    final metas = [...state.metas];
    final index = metas.indexWhere((m) => m.id == meta.id);
    if (index == -1) {
      metas.add(meta);
    } else {
      metas[index] = meta;
    }
    state = state.copyWith(metas: metas);
  }

  Future<void> deleteEventMeta(String eventId) async {
    _eventRepository.deleteEventMeta(eventId);
    final metas = state.metas
        .where((meta) => meta.id != eventId)
        .toList(growable: false);
    state = state.copyWith(metas: metas);
  }

  Future<void> upsertTransaction(Transaction tx) async {
    final now = DateTime.now();
    final updatedTx = tx.updatedAt == null ? tx.copyWith(updatedAt: now) : tx;
    _transactionRepository.upsertTransaction(updatedTx);
    final txs = [...state.transactions];
    final index = txs.indexWhere((t) => t.id == updatedTx.id);
    if (index == -1) {
      txs.add(updatedTx);
    } else {
      txs[index] = updatedTx;
    }
    state = state.copyWith(transactions: txs);
  }

  Future<void> deleteTransaction(String txId) async {
    _transactionRepository.deleteTransaction(txId);
    final now = DateTime.now();
    final txs = state.transactions.map((t) {
      if (t.id != txId) return t;
      return t.copyWith(deletedAt: now, updatedAt: now);
    }).toList(growable: false);
    state = state.copyWith(transactions: txs);
  }
}

final eventStateProvider =
    StateNotifierProvider<EventStateNotifier, EventState>((ref) {
  return EventStateNotifier(
    eventRepository: ref.read(eventRepositoryProvider),
    transactionRepository: ref.read(transactionRepositoryProvider),
  );
});

final eventRepositoryProvider = Provider<EventRepository>((ref) => _eventRepo);
final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) => _txRepo);

final EventRepository _eventRepo = MockEventRepository(
  initialEvents: List<EventSummary>.from(event_mock.mockEvents),
  initialMetas: List<EventMeta>.from(event_meta_mock.mockEventMetas),
);

final TransactionRepository _txRepo = MockTransactionRepository(
  List<Transaction>.from(transactions_mock.mockDomainTransactions),
);

final eventSummariesProvider = Provider<List<EventSummary>>((ref) {
  final state = ref.watch(eventStateProvider);
  return _deriveEventSummaries(state.metas, state.transactions);
});

final eventMetaByIdProvider = Provider.family<EventMeta?, String>((ref, eventId) {
  final metas = ref.watch(eventStateProvider.select((s) => s.metas));
  for (final meta in metas) {
    if (meta.id == eventId && meta.deletedAt == null) return meta;
  }
  return null;
});

final transactionsByEventIdProvider =
    Provider.family<List<Transaction>, String>((ref, eventId) {
  final txs = ref.watch(eventStateProvider.select((s) => s.transactions));
  final filtered = txs
      .where((t) => t.eventId == eventId && t.deletedAt == null)
      .toList();
  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

final settlementProvider =
    Provider.family<SettlementSummary?, String>((ref, eventId) {
  final meta = ref.watch(eventMetaByIdProvider(eventId));
  if (meta == null) return null;
  final txs = ref.watch(transactionsByEventIdProvider(eventId));
  return _buildSettlementSummary(meta, txs);
});

List<EventSummary> _deriveEventSummaries(
  List<EventMeta> metas,
  List<Transaction> txs,
) {
  return metas
      .where((meta) => meta.deletedAt == null)
      .map((meta) {
        final eventTxs = txs
            .where((t) => t.eventId == meta.id && t.deletedAt == null)
            .toList(growable: false);
        final participantIds = _mergeParticipantIds(meta.participantIds, eventTxs);
        final lastUpdatedAt = _latestUpdatedAt(meta.updatedAt, eventTxs);
        final net = _calcNetBalances(eventTxs, participantIds);
        final totalUnsettled =
            net.values.where((v) => v > 0).fold<int>(0, (p, v) => p + v);
        final isSettled = totalUnsettled == 0;
        return EventSummary(
          id: meta.id,
          title: meta.title,
          isSettled: isSettled,
          participantIds: participantIds,
          lastUpdatedAt: lastUpdatedAt,
          totalUnsettledAmount: totalUnsettled,
        );
      })
      .toList(growable: false);
}

List<String> _mergeParticipantIds(
  List<String> base,
  List<Transaction> txs,
) {
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
      net.update(paidBy, (v) => v + tx.totalAmount,
          ifAbsent: () => tx.totalAmount);
      for (final entry in shares.entries) {
        net.update(entry.key, (v) => v - entry.value,
            ifAbsent: () => -entry.value);
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

SettlementSummary _buildSettlementSummary(
  EventMeta meta,
  List<Transaction> txs,
) {
  final memberIds = _mergeParticipantIds(meta.participantIds, txs);
  final balances = _calcNetBalances(txs, memberIds);
  final instructions = _simplifyBalances(balances);
  return SettlementSummary(
    eventId: meta.id,
    balancesByUserId: balances,
    instructions: instructions,
    generatedAt: DateTime.now(),
  );
}

class _BalanceItem {
  _BalanceItem(this.userId, this.amount);
  final String userId;
  int amount;
}

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
