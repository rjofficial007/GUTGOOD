import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class ChatFirestoreService {
  Future<String?> saveMessage(ChatMessage message);
  Stream<List<ChatMessage>> getMessagesStream({int limit = 50});
  Future<List<ChatMessage>> getMessages({int? limit, DateTime? since});
  Future<List<ChatMessage>> getOlderMessages({required int limit, required DateTime before});
  Future<void> updateMessageFeedback(String messageId, String feedback);
  Future<void> deleteMessage(String messageId);
}

class ChatFirestoreServiceImpl implements ChatFirestoreService {
  ChatFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db}) : _auth = auth, _db = db;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? get _uid => _auth.currentUser?.uid;
  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('user_profiles').doc(uid);
  }

  @override
  Future<String?> saveMessage(ChatMessage message) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('chat_history').doc();
      final cloudSafeData = message.toMap()..remove('id');
      final data = {...cloudSafeData, 'firestoreId': docRef.id, 'source': message.source ?? 'chat', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error saving message', error: e);
      return null;
    }
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream({int limit = 50}) {
    final doc = _userDoc;
    if (doc == null) return const Stream.empty();
    return doc
        .collection('chat_history')
        .orderBy('time', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Chat stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromMap({...doc.data(), 'firestoreId': doc.id})).toList());
  }

  @override
  Future<List<ChatMessage>> getMessages({int? limit, DateTime? since}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      var query = doc.collection('chat_history').orderBy('time', descending: true);

      if (since != null) {
        query = query.where('time', isGreaterThanOrEqualTo: since.toIso8601String());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ChatMessage.fromMap({...doc.data(), 'firestoreId': doc.id})).toList();
    } catch (e) {
      AppLogger.firestore('Error getting messages', error: e);
      return [];
    }
  }

  @override
  Future<List<ChatMessage>> getOlderMessages({required int limit, required DateTime before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      final query = doc
          .collection('chat_history')
          .orderBy('time', descending: true)
          .where('time', isLessThan: before.toIso8601String())
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ChatMessage.fromMap({...doc.data(), 'firestoreId': doc.id})).toList();
    } catch (e) {
      AppLogger.firestore('Error getting older messages', error: e);
      return [];
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('chat_history').doc(messageId).delete();
    } catch (e) {
      AppLogger.firestore('Error deleting message', error: e);
    }
  }

  @override
  Future<void> updateMessageFeedback(String messageId, String feedback) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('chat_history').doc(messageId).update({'feedback': feedback});
    } catch (e) {
      AppLogger.firestore('Error updating message feedback', error: e);
    }
  }
}
