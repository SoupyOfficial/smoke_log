import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  LogRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _userLogsCollection {
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  Future<void> addLog(Log log) async {
    await _userLogsCollection.add(log.toMap());
  }

  Stream<List<Log>> streamLogs() {
    return _userLogsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Log.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateLog(Log log) async {
    if (log.id == null) throw Exception('Log ID is null');
    await _userLogsCollection.doc(log.id).update(log.toMap());
  }

  Future<void> deleteLog(String logId) async {
    await _userLogsCollection.doc(logId).delete();
  }
}
