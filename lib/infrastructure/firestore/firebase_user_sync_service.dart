import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shakuyousho_app/core/config/app_flags.dart';
import 'package:shakuyousho_app/domain/models/user_model.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_collections.dart';

/// Firebase Auth の UID をキーに users コレクションへ同期するサービス。
class FirebaseUserSyncService {
  const FirebaseUserSyncService();

  /// 現在ログイン中ユーザーの Firestore データを取得する。
  Future<User?> fetchCurrentUser({
    required String fallbackAppUserId,
    String fallbackDisplayName = '',
  }) async {
    if (!kUseFirebase) return null;
    final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) return null;

    final snap = await FirestoreCollections.usersRef().doc(authUser.uid).get();
    final data = snap.data();
    if (data == null) return null;

    final appUserId = _nonEmptyString(data['appUserId']) ?? fallbackAppUserId;
    final displayName =
        _nonEmptyString(data['displayName']) ?? fallbackDisplayName;

    return User(
      id: appUserId,
      displayName: displayName,
      myCode: _nonEmptyString(data['myCode']),
      avatarUrl: _nonEmptyString(data['avatarUrl']),
      createdAt: _dateFromDynamic(data['createdAt']),
      deletedAt: _dateFromDynamic(data['deletedAt']),
    );
  }

  /// 現在ログイン中ユーザーの Firestore データを作成/更新する。
  Future<void> syncCurrentUser(User user) async {
    if (!kUseFirebase) return;
    final authUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final payload = <String, dynamic>{
      'appUserId': user.id,
      'displayName': user.displayName,
      'myCode': user.myCode,
      'avatarUrl': user.avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (user.createdAt != null) {
      payload['createdAt'] = Timestamp.fromDate(user.createdAt!);
    }
    if (user.deletedAt != null) {
      payload['deletedAt'] = Timestamp.fromDate(user.deletedAt!);
    }

    await FirestoreCollections.usersRef()
        .doc(authUser.uid)
        .set(payload, SetOptions(merge: true));
  }
}

String? _nonEmptyString(dynamic raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
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
