import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore のコレクション名と参照を集約
class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String events = 'events';
  static const String transactions = 'transactions';
  static const String friends = 'friends';
  static const String loans = 'loans';
  static const String messages = 'messages';
  static const String threads = 'threads';

  static CollectionReference<Map<String, dynamic>> usersRef([
    FirebaseFirestore? db,
  ]) =>
      (db ?? FirebaseFirestore.instance).collection(users);

  static CollectionReference<Map<String, dynamic>> eventsRef([
    FirebaseFirestore? db,
  ]) =>
      (db ?? FirebaseFirestore.instance).collection(events);

  static CollectionReference<Map<String, dynamic>> eventTransactionsRef(
    String eventId, [
    FirebaseFirestore? db,
  ]) =>
      eventsRef(db).doc(eventId).collection(transactions);
}
