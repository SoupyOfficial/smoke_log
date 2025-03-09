import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  // Cache configuration
  static const Duration cacheFreshness = Duration(hours: 12);

  LogRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _userLogsCollection {
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  // Add log with offline support
  Future<void> addLog(Log log) async {
    try {
      await _userLogsCollection.add(log.toMap());
    } catch (e) {
      // Handle offline cases
      if (e is FirebaseException && e.code == 'unavailable') {
        // Firestore SDK will auto-queue the write when connection returns
        // Just let the caller know it's been queued
        print('Network unavailable, operation queued for sync');
      } else {
        rethrow;
      }
    }
  }

  // Stream logs with cache first, server update
  Stream<List<Log>> streamLogs({bool cacheOnly = false}) {
    final query = _userLogsCollection.orderBy('timestamp', descending: true);

    if (cacheOnly) {
      return query
          .get(const GetOptions(source: Source.cache))
          .asStream()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Log.fromMap(doc.data(), doc.id))
            .toList();
      });
    } else {
      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Log.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
  }

  // Get logs from cache first, then server if needed
  Future<List<Log>> getLogs({Source source = Source.cache}) async {
    try {
      final snapshot = await _userLogsCollection
          .orderBy('timestamp', descending: true)
          .get(GetOptions(source: source));

      return snapshot.docs
          .map((doc) => Log.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (e is FirebaseException &&
          e.code == 'unavailable' &&
          source == Source.cache) {
        // If cache read fails, try server
        return getLogs(source: Source.server);
      }
      rethrow;
    }
  }

  // Update with optimistic UI approach
  Future<void> updateLog(Log log) async {
    if (log.id == null) throw Exception('Log ID is null');

    try {
      await _userLogsCollection.doc(log.id).update(log.toMap());
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, update queued for sync');
      } else {
        rethrow;
      }
    }
  }

  // Delete with optimistic UI approach
  Future<void> deleteLog(String logId) async {
    try {
      await _userLogsCollection.doc(logId).delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, deletion queued for sync');
      } else {
        rethrow;
      }
    }
  }

  // Force a refresh from the server
  Future<List<Log>> refreshLogs() async {
    return getLogs(source: Source.server);
  }

  // Check if we have cached data
  Future<bool> hasCachedLogs() async {
    try {
      final snapshot = await _userLogsCollection
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Batch operations for efficiency
  Future<void> batchUpdateLogs(List<Log> logs) async {
    final batch = _firestore.batch();

    for (final log in logs) {
      if (log.id == null) continue;
      batch.update(_userLogsCollection.doc(log.id), log.toMap());
    }

    await batch.commit();
  }
}
