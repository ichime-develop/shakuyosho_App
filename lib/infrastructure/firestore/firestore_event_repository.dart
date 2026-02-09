import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/repositories/event_repository.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_collections.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error.dart';

/// Firestore-backed implementation for EventMeta persistence.
class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({
    FirebaseFirestore? db,
    firebase_auth.FirebaseAuth? auth,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final firebase_auth.FirebaseAuth _auth;

  @override
  Future<List<EventMeta>> getAllEventMetas() async {
    try {
      final authUid = _requireAuthUid();
      // Security Rules: event read は memberUids に自分が含まれることが前提。
      final snap = await FirestoreCollections.eventsRef(_db)
          .where('memberUids', arrayContains: authUid)
          .get();
      return snap.docs
          .map((doc) => _fromDoc(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'event getAll');
    }
  }

  @override
  Future<EventMeta?> getEventMetaById(String eventId) async {
    try {
      final snap = await FirestoreCollections.eventsRef(_db).doc(eventId).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return _fromDoc(snap.id, data);
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'event getById');
    }
  }

  @override
  Future<void> upsertEventMeta(EventMeta meta) async {
    try {
      final authUid = _requireAuthUid();
      final ref = FirestoreCollections.eventsRef(_db).doc(meta.id);
      Map<String, dynamic>? currentData;
      try {
        // create 前の未存在ドキュメント read は rules 上 permission-denied になり得る。
        // その場合は「新規作成」として扱う。
        final currentSnap = await ref.get();
        currentData = currentSnap.data();
      } on FirebaseException catch (e) {
        final code = e.code.toLowerCase();
        if (code != 'permission-denied' && code != 'not-found') {
          rethrow;
        }
      }

      final ownerUid =
          _nonEmptyString(currentData?['ownerUid']) ?? authUid;
      final memberUids = _memberUidsForWrite(
        currentData: currentData,
        participantIds: meta.participantIds,
        authUid: authUid,
      );
      final createdAt =
          _dateFromDynamic(currentData?['createdAt']) ?? meta.createdAt;

      await ref.set(
        {
          'id': meta.id,
          'title': meta.title,
          // 既存アプリ側互換（表示や集計で利用）
          'participantIds': meta.participantIds,
          // ルール評価用
          'ownerUid': ownerUid,
          'memberUids': memberUids,
          // 状態
          'status': meta.status.name,
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(meta.updatedAt),
          'deletedAt': meta.deletedAt == null
              ? null
              : Timestamp.fromDate(meta.deletedAt!),
          'schemaVersion': 1,
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'event upsert');
    }
  }

  @override
  Future<void> deleteEventMeta(String eventId) async {
    try {
      final ref = FirestoreCollections.eventsRef(_db).doc(eventId);
      final current = await ref.get();
      if (!current.exists) return;
      final now = DateTime.now();
      await ref.set({
        'deletedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    } catch (e, st) {
      throw mapFirestoreError(e, st, operation: 'event delete');
    }
  }

  EventMeta _fromDoc(String id, Map<String, dynamic> data) {
    final participants = _stringList(data['participantIds']);
    final fallbackMembers = _stringList(data['memberUids']);
    final createdAt = _dateFromDynamic(data['createdAt']) ?? DateTime.now();
    final updatedAt =
        _dateFromDynamic(data['updatedAt']) ??
        _dateFromDynamic(data['createdAt']) ??
        DateTime.now();
    final deletedAt = _dateFromDynamic(data['deletedAt']);
    return EventMeta(
      id: id,
      title: _nonEmptyString(data['title']) ?? '',
      participantIds: participants.isNotEmpty ? participants : fallbackMembers,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: _statusFromDynamic(data['status']),
      deletedAt: deletedAt,
    );
  }

  List<String> _memberUidsForWrite({
    required Map<String, dynamic>? currentData,
    required List<String> participantIds,
    required String authUid,
  }) {
    // 既存ドキュメントがある場合は、ルール違反を避けるため memberUids を維持する。
    if (currentData != null) {
      final existingMemberUids = _stringList(currentData['memberUids']);
      if (existingMemberUids.isNotEmpty) {
        return _normalizeMemberUids(existingMemberUids, authUid);
      }
      final legacyParticipantIds = _stringList(currentData['participantIds']);
      return _normalizeMemberUids(legacyParticipantIds, authUid);
    }
    // create 時のみ participantIds を memberUids に反映する。
    return _normalizeMemberUids(participantIds, authUid);
  }

  List<String> _normalizeMemberUids(List<String> raw, String authUid) {
    final values = <String>{};
    for (final value in raw) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        values.add(normalized);
      }
    }
    values.add(authUid);
    return values.toList(growable: false);
  }

  String _requireAuthUid() {
    final authUid = _auth.currentUser?.uid;
    if (authUid == null || authUid.isEmpty) {
      throw const AppError(
        type: AppErrorType.unauthorized,
        userMessage: '',
        message: 'firebase auth currentUser is null',
      );
    }
    return authUid;
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

DateTime? _dateFromDynamic(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

EventStatus _statusFromDynamic(dynamic raw) {
  if (raw is EventStatus) return raw;
  if (raw is String) {
    for (final status in EventStatus.values) {
      if (status.name == raw) return status;
    }
  }
  return EventStatus.inProgress;
}
