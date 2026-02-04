import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/contacts_mock.dart';
import 'package:shakuyousho_app/data/mock/loans_mock.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/friend_model.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';
import 'package:shakuyousho_app/domain/repositories/friend_repository.dart';
import 'package:shakuyousho_app/domain/repositories/loan_repository.dart';
import 'package:shakuyousho_app/domain/repositories/user_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/hive_friend_repository.dart';
import 'package:shakuyousho_app/infrastructure/repositories/hive_loan_repository.dart';

// ────────────────────────────────────────────────────────────────
// Repository Providers（DI用）
// ────────────────────────────────────────────────────────────────

final Box<Map> _loanBox = Hive.box<Map>('loans');
final Box<Map> _friendBox = Hive.box<Map>('friends');
final Box<Map> _threadBox = Hive.box<Map>('threads');
final Box<Map> _userBox = Hive.box<Map>('users');

void _seedLoansIfEmpty({required Box<Map> box}) {
  final hasLive = box.values.any(
    (raw) => Loan.fromMap(_castMap(raw)).deletedAt == null,
  );
  if (hasLive) return;
  final userIds = _userIdsFromBox(_userBox);
  final friendIds = _friendIdsFromThreads(_threadBox).toSet();
  for (final loan in mockLoans) {
    if (!userIds.contains(loan.counterpartyId)) continue;
    if (!friendIds.contains(loan.counterpartyId)) continue;
    box.put(loan.id, loan.toMap());
  }
}

void _seedFriendsIfEmpty({required Box<Map> box}) {
  final hasLive = box.values.any(
    (raw) => Friend.fromMap(_castMap(raw)).deletedAt == null,
  );
  if (hasLive) return;
  final userIds = _userIdsFromBox(_userBox);
  final createdAtByUserId = _friendCreatedAtFromThreads(_threadBox);

  for (final entry in createdAtByUserId.entries) {
    final userId = entry.key;
    if (!userIds.contains(userId)) continue;
    final friend = Friend(userId: userId, createdAt: entry.value);
    box.put(friend.userId, friend.toMap());
  }

  if (box.isNotEmpty) return;
  // フォールバック（threads未投入時）: contacts_mock に寄せる
  for (final contact in mockContacts) {
    if (contact.ownerUserId != currentUserId) continue;
    if (!userIds.contains(contact.peerUserId)) continue;
    final friend = Friend(
      userId: contact.peerUserId,
      createdAt: contact.createdAt ?? DateTime(2024, 1, 1),
    );
    box.put(friend.userId, friend.toMap());
  }
}

/// LoanRepository（Map保存）
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  // Ensure users/threads seed are initialized before friend/loan seeds.
  ref.read(userListProvider);
  ref.read(threadListProvider);
  _seedLoansIfEmpty(box: _loanBox);
  return HiveLoanRepository(loanBox: _loanBox);
});

/// FriendRepository（Map保存）
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  // Ensure users/threads seed are initialized before friend/loan seeds.
  ref.read(userListProvider);
  ref.read(threadListProvider);
  _seedFriendsIfEmpty(box: _friendBox);
  return HiveFriendRepository(friendBox: _friendBox);
});

// ────────────────────────────────────────────────────────────────
// Loan Providers
// ────────────────────────────────────────────────────────────────

/// 全Loan一覧
final allLoansProvider = FutureProvider<List<Loan>>((ref) async {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getAll();
});

/// 相手ユーザーIDで絞り込んだLoan一覧
final loansByCounterpartyProvider = FutureProvider.family<List<Loan>, String>((
  ref,
  counterpartyId,
) async {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getByCounterparty(counterpartyId);
});

/// IDでLoan取得
final loanByIdProvider = FutureProvider.family<Loan?, String>((ref, id) async {
  final repo = ref.watch(loanRepositoryProvider);
  return repo.getById(id);
});

/// 貸借合計（残額ベース）
final loanTotalsProvider = FutureProvider<({int lentTotal, int borrowedTotal})>(
  (ref) async {
    final repo = ref.watch(loanRepositoryProvider);
    return repo.calcTotals();
  },
);

// ────────────────────────────────────────────────────────────────
// Friend Providers
// ────────────────────────────────────────────────────────────────

/// 全友達一覧
final allFriendsProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getAll();
});

/// 友達検索
final friendSearchProvider = FutureProvider.family<List<Friend>, String>((
  ref,
  query,
) async {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.search(query);
});

// ────────────────────────────────────────────────────────────────
// 友達別サマリー（FR0100用）
// ────────────────────────────────────────────────────────────────

/// 友達別の貸借サマリー
class FriendSummary {
  const FriendSummary({
    required this.friendId,
    required this.displayName,
    required this.lentTotal,
    required this.borrowedTotal,
    this.nearestDueDate,
  });

  final String friendId;
  final String displayName;
  final int lentTotal; // かした残額合計
  final int borrowedTotal; // かりた残額合計
  final DateTime? nearestDueDate; // 最も近い返済期限

  /// 差額（プラス=かした方が多い、マイナス=かりた方が多い）
  int get balance => lentTotal - borrowedTotal;
}

/// 全友達のサマリー一覧
final friendSummariesProvider = FutureProvider<List<FriendSummary>>((
  ref,
) async {
  final friends = await ref.watch(allFriendsProvider.future);
  final allLoans = await ref.watch(allLoansProvider.future);
  ref.watch(userListProvider);
  final userRepo = ref.read(userRepositoryProvider);

  final summaries = <FriendSummary>[];

  for (final friend in friends) {
    final loans = allLoans
        .where((l) => l.counterpartyId == friend.userId)
        .toList();
    final displayName =
        userRepo.getById(friend.userId)?.displayName ?? friend.userId;

    var lentTotal = 0;
    var borrowedTotal = 0;
    DateTime? nearestDue;

    for (final loan in loans) {
      if (loan.isRepaid) continue; // 完済済みは除外

      if (loan.direction == LoanDirection.lent) {
        lentTotal += loan.remainingYen;
      } else {
        borrowedTotal += loan.remainingYen;
      }

      // 最も近い返済期限を更新
      if (nearestDue == null || loan.dueDate.isBefore(nearestDue)) {
        nearestDue = loan.dueDate;
      }
    }

    summaries.add(
      FriendSummary(
        friendId: friend.userId,
        displayName: displayName,
        lentTotal: lentTotal,
        borrowedTotal: borrowedTotal,
        nearestDueDate: nearestDue,
      ),
    );
  }

  return summaries;
});

// ────────────────────────────────────────────────────────────────
// Loan Actions（状態変更用）
// ────────────────────────────────────────────────────────────────

/// Loanの操作を行うNotifier
class LoanActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  LoanRepository get _repo => ref.read(loanRepositoryProvider);

  /// 借用書を作成
  Future<Loan> createLoan({
    required LoanDirection direction,
    required String counterpartyId,
    required int amountYen,
    required String purpose,
    required DateTime dueDate,
  }) async {
    final userRepo = ref.read(userRepositoryProvider);
    final counterpartyName =
        userRepo.getById(counterpartyId)?.displayName ?? counterpartyId;

    final loan = Loan(
      id: _repo.newId(),
      direction: direction,
      counterpartyId: counterpartyId,
      legacyCounterpartyName: counterpartyName,
      amountYen: amountYen,
      purpose: purpose,
      dueDate: dueDate,
      status: direction == LoanDirection.borrowed
          ? LoanStatus.pending
          : LoanStatus.approved,
      createdAt: DateTime.now(),
      iouNo:
          'IOU-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      repayments: const [],
    );

    await _repo.upsert(loan);
    _invalidateAll();
    return loan;
  }

  /// 返済を申請（status → pending）
  Future<void> requestRepay(String loanId) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;

    final updated = loan.copyWith(status: LoanStatus.pending);
    await _repo.upsert(updated);
    _invalidateAll();
  }

  /// 返済を承認（repayments追加 + status → approved）
  Future<void> approveRepay(String loanId, int repayYen) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;

    final newRepayments = [
      ...loan.repayments,
      Repayment(amountYen: repayYen, paidAt: DateTime.now()),
    ];

    final updated = loan.copyWith(
      status: LoanStatus.approved,
      repayments: newRepayments,
    );
    await _repo.upsert(updated);
    _invalidateAll();
  }

  /// 返済を却下（status → approved に戻す）
  Future<void> rejectRepay(String loanId) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;

    final updated = loan.copyWith(status: LoanStatus.approved);
    await _repo.upsert(updated);
    _invalidateAll();
  }

  /// 借用書を削除
  Future<void> deleteLoan(String loanId) async {
    await _repo.delete(loanId);
    _invalidateAll();
  }

  /// 借用書を承認（pending → approved）
  Future<void> approveLoan(String loanId) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;
    if (loan.status != LoanStatus.pending) return;

    final updated = loan.copyWith(status: LoanStatus.approved);
    await _repo.upsert(updated);
    _invalidateAll();
  }

  /// 借用書を却下（pending → rejected）
  Future<void> rejectLoan(String loanId) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;
    if (loan.status != LoanStatus.pending) return;

    final updated = loan.copyWith(status: LoanStatus.rejected);
    await _repo.upsert(updated);
    _invalidateAll();
  }

  /// 返済を追加
  Future<void> addRepayment(String loanId, int amountYen) async {
    final loan = await _repo.getById(loanId);
    if (loan == null) return;
    if (amountYen <= 0) return;

    final newRepayments = [
      ...loan.repayments,
      Repayment(amountYen: amountYen, paidAt: DateTime.now()),
    ];

    final updated = loan.copyWith(repayments: newRepayments);
    await _repo.upsert(updated);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidate(allLoansProvider);
    ref.invalidate(loanTotalsProvider);
    ref.invalidate(friendSummariesProvider);
  }
}

final loanActionsProvider = NotifierProvider<LoanActionsNotifier, void>(
  LoanActionsNotifier.new,
);

Map<String, dynamic> _castMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

Set<String> _userIdsFromBox(Box<Map> userBox) {
  return userBox.values
      .map((raw) => User.fromMap(_castMap(raw)))
      .where((u) => u.deletedAt == null)
      .map((u) => u.id)
      .where((id) => id.isNotEmpty)
      .toSet();
}

Set<String> _friendIdsFromThreads(Box<Map> threadBox) {
  final ids = <String>{};
  for (final raw in threadBox.values) {
    final thread = Thread.fromMap(_castMap(raw));
    if (thread.deletedAt != null) continue;
    if (thread.type != 'personal') continue;
    if (!thread.participantIds.contains(currentUserId)) continue;
    final peer = thread.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (peer.isNotEmpty) ids.add(peer);
  }
  return ids;
}

Map<String, DateTime> _friendCreatedAtFromThreads(Box<Map> threadBox) {
  final createdAtByUserId = <String, DateTime>{};
  for (final raw in threadBox.values) {
    final thread = Thread.fromMap(_castMap(raw));
    if (thread.deletedAt != null) continue;
    if (thread.type != 'personal') continue;
    if (!thread.participantIds.contains(currentUserId)) continue;
    final peer = thread.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (peer.isEmpty) continue;
    final existing = createdAtByUserId[peer];
    if (existing == null || thread.createdAt.isBefore(existing)) {
      createdAtByUserId[peer] = thread.createdAt;
    }
  }
  return createdAtByUserId;
}

// ────────────────────────────────────────────────────────────────
// Friend Actions（状態変更用）
// ────────────────────────────────────────────────────────────────

/// 友達の操作を行うNotifier
class FriendActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  FriendRepository get _repo => ref.read(friendRepositoryProvider);
  UserRepository get _userRepo => ref.read(userRepositoryProvider);

  /// 友達を追加
  Future<void> addFriend(String input) async {
    final resolved = _resolveUserId(input);
    if (resolved == null) return;
    await _repo.add(resolved);
    _invalidateAll();
  }

  /// 友達を削除
  Future<void> removeFriend(String input) async {
    final resolved = _resolveUserId(input);
    if (resolved == null) return;
    await _repo.remove(resolved);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidate(allFriendsProvider);
    ref.invalidate(friendSummariesProvider);
  }

  String? _resolveUserId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final direct = _userRepo.getById(trimmed);
    if (direct != null) return direct.id;
    for (final user in _userRepo.getAll()) {
      if (user.displayName == trimmed) return user.id;
    }
    return null;
  }
}

final friendActionsProvider = NotifierProvider<FriendActionsNotifier, void>(
  FriendActionsNotifier.new,
);
