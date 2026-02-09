import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/domain/repositories/transaction_repository.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_collections.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_error_mapper.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_event_repository.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';

/// Firestore-backed implementation for Transaction persistence.
class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({
    fs.FirebaseFirestore? db,
    EventRepository? eventRepository,
  }) : _db = db ?? fs.FirebaseFirestore.instance,
       _eventRepository =
           eventRepository ?? FirestoreEventRepository(db: db);

  final fs.FirebaseFirestore _db;
  final EventRepository _eventRepository;

  @override
  Future<List<Transaction>> getAll() async {
    try {
      // Security Rules 準拠のため、閲覧可能イベント単位で取得する。
      final events = await _eventRepository.getAllEventMetas();
      final futures = events
          .where((event) => event.deletedAt == null)
          .map((event) => getByEventId(event.id));
      final grouped = await Future.wait(futures);
      return grouped.expand((txs) => txs).toList(growable: false);
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'transaction getAll');
    }
  }

  @override
  Future<List<Transaction>> getByEventId(String eventId) async {
    try {
      final snap = await FirestoreCollections.eventTransactionsRef(
        eventId,
        _db,
      ).get();
      return snap.docs
          .map((doc) => _fromDoc(doc.id, doc.data(), doc.reference))
          .where((tx) => tx.deletedAt == null)
          .toList(growable: false);
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'transaction getByEventId');
    }
  }

  @override
  Future<void> upsert(Transaction tx) async {
    final eventId = tx.eventId;
    if (eventId == null || eventId.isEmpty) {
      throw const AppError(
        type: AppErrorType.invalid,
        userMessage: '',
        message: 'transaction upsert requires eventId',
      );
    }
    try {
      final ref = FirestoreCollections.eventTransactionsRef(
        eventId,
        _db,
      ).doc(tx.id);
      await ref.set(_toPayload(tx), fs.SetOptions(merge: true));
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'transaction upsert');
    }
  }

  @override
  Future<void> delete(String txId) async {
    try {
      final snap = await _db
          .collectionGroup(FirestoreCollections.transactions)
          .where(fs.FieldPath.documentId, isEqualTo: txId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;

      final now = DateTime.now();
      await snap.docs.first.reference.set({
        'deletedAt': fs.Timestamp.fromDate(now),
        'updatedAt': fs.Timestamp.fromDate(now),
      }, fs.SetOptions(merge: true));
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'transaction delete');
    }
  }

  Transaction _fromDoc(
    String id,
    Map<String, dynamic> data,
    fs.DocumentReference<Map<String, dynamic>> ref,
  ) {
    final eventId =
        _nonEmptyString(data['eventId']) ?? ref.parent.parent?.id;
    final totalAmount = _intFrom(data['totalAmount'] ?? data['amountYen']);
    final shares = _stringIntMap(data['shares']);
    final participantIds = _stringList(data['participantIds']);

    return Transaction(
      id: id,
      eventId: eventId,
      type: _txTypeFromDynamic(data['type']),
      title: _nonEmptyString(data['title']) ?? '',
      date: _dateFromDynamic(data['date'] ?? data['occurredAt']) ?? DateTime.now(),
      currency: _nonEmptyString(data['currency']) ?? 'JPY',
      totalAmount: totalAmount,
      participantIds: participantIds,
      paidBy: _nonEmptyString(data['paidBy'] ?? data['payerUid']),
      shares: shares,
      fromUserId: _nonEmptyString(data['fromUserId']),
      toUserId: _nonEmptyString(data['toUserId']),
      repaymentAmount: _intFromNullable(data['repaymentAmount']),
      createdBy: _nonEmptyString(data['createdBy'] ?? data['createdByUid']) ?? '',
      createdAt:
          _dateFromDynamic(data['createdAt']) ??
          _dateFromDynamic(data['updatedAt']) ??
          DateTime.now(),
      updatedAt: _dateFromDynamic(data['updatedAt']),
      deletedAt: _dateFromDynamic(data['deletedAt']),
    );
  }

  Map<String, dynamic> _toPayload(Transaction tx) {
    final splitUids = tx.shares?.keys.toList(growable: false) ?? const <String>[];
    final payload = <String, dynamic>{
      'id': tx.id,
      'eventId': tx.eventId,
      'type': tx.type.name,
      'title': tx.title,
      'date': fs.Timestamp.fromDate(tx.date),
      'currency': tx.currency,
      'totalAmount': tx.totalAmount,
      'participantIds': tx.participantIds,
      'paidBy': tx.paidBy,
      'shares': tx.shares,
      'fromUserId': tx.fromUserId,
      'toUserId': tx.toUserId,
      'repaymentAmount': tx.repaymentAmount,
      'createdBy': tx.createdBy,
      'createdAt': fs.Timestamp.fromDate(tx.createdAt),
      'updatedAt': fs.Timestamp.fromDate(tx.updatedAt ?? DateTime.now()),
      'deletedAt': tx.deletedAt == null
          ? null
          : fs.Timestamp.fromDate(tx.deletedAt!),
      // ルール・将来互換用
      'amountYen': tx.totalAmount,
      'payerUid': tx.paidBy,
      'splitUids': splitUids,
      'createdByUid': tx.createdBy,
      'occurredAt': fs.Timestamp.fromDate(tx.date),
      'schemaVersion': 1,
    };
    return payload;
  }
}

String? _nonEmptyString(dynamic raw) {
  if (raw is! String) return null;
  final v = raw.trim();
  return v.isEmpty ? null : v;
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw.map((e) => '$e').toList(growable: false);
}

Map<String, int>? _stringIntMap(dynamic raw) {
  if (raw is! Map) return null;
  final result = <String, int>{};
  raw.forEach((key, value) {
    final amount = _intFrom(value);
    result['$key'] = amount;
  });
  return result;
}

int _intFrom(dynamic raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

int? _intFromNullable(dynamic raw) {
  if (raw == null) return null;
  return _intFrom(raw);
}

DateTime? _dateFromDynamic(dynamic raw) {
  if (raw == null) return null;
  if (raw is fs.Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

TxType _txTypeFromDynamic(dynamic raw) {
  if (raw is TxType) return raw;
  if (raw is String) {
    for (final type in TxType.values) {
      if (type.name == raw) return type;
    }
  }
  return TxType.expense;
}
