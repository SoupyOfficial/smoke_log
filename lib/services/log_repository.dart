import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final String userId;

  // Cache configuration
  static const Duration cacheFreshness = Duration(hours: 12);

  LogRepository(this.userId);

  CollectionReference<Map<String, dynamic>> get _userLogsCollection {
    return _firestore.collection('users').doc(userId).collection('logs');
  }

  // Track Firestore operations
  Future<void> _trackFirestoreOperation(
    String operationType, {
    String? logId,
    bool isOffline = false,
    Source? source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'firestore_operation',
        parameters: {
          'operation_type': operationType,
          'collection': 'logs',
          'user_id': userId,
          'log_id': logId ?? 'none',
          'offline': isOffline ? 1 : 0, // Convert boolean to number
          'source': source?.toString() ?? 'default',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      // Fail silently - analytics should never break app functionality
      print('Analytics error: $e');
    }
  }

  // Add log with offline support
  Future<void> addLog(Log log) async {
    bool isOffline = false;

    try {
      await _userLogsCollection.add(log.toMap());
      await _trackFirestoreOperation('create', logId: log.id);
    } catch (e) {
      // Handle offline cases
      if (e is FirebaseException && e.code == 'unavailable') {
        // Firestore SDK will auto-queue the write when connection returns
        isOffline = true;
        print('Network unavailable, operation queued for sync');
      } else {
        rethrow;
      }
    } finally {
      await _trackFirestoreOperation(
        'create',
        logId: log.id,
        isOffline: isOffline,
      );
    }
  }

  // Stream logs with cache first, server update
  Stream<List<Log>> streamLogs({bool cacheOnly = false}) {
    final query = _userLogsCollection.orderBy('timestamp', descending: true);

    // Track the read operation
    _trackFirestoreOperation('stream_read',
        source: cacheOnly ? Source.cache : null);

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

      await _trackFirestoreOperation('get_read', source: source);

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

      await _trackFirestoreOperation('get_read_error',
          source: source,
          isOffline: e is FirebaseException && e.code == 'unavailable');

      rethrow;
    }
  }

  // Update with optimistic UI approach
  Future<void> updateLog(Log log) async {
    bool isOffline = false;

    try {
      await _userLogsCollection.doc(log.id).update(log.toMap());
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        isOffline = true;
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, update queued for sync');
      } else {
        rethrow;
      }
    } finally {
      await _trackFirestoreOperation(
        'update',
        logId: log.id,
        isOffline: isOffline,
      );
    }
  }

  // Delete with optimistic UI approach
  Future<void> deleteLog(String logId) async {
    bool isOffline = false;

    try {
      await _userLogsCollection.doc(logId).delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        isOffline = true;
        // Operation will be queued automatically by Firestore SDK
        print('Network unavailable, deletion queued for sync');
      } else {
        rethrow;
      }
    } finally {
      await _trackFirestoreOperation(
        'delete',
        logId: logId,
        isOffline: isOffline,
      );
    }
  }

  // Force a refresh from the server
  Future<List<Log>> refreshLogs() async {
    await _trackFirestoreOperation('refresh', source: Source.server);
    return getLogs(source: Source.server);
  }

  // Check if we have cached data
  Future<bool> hasCachedLogs() async {
    try {
      final snapshot = await _userLogsCollection
          .limit(1)
          .get(const GetOptions(source: Source.cache));

      await _trackFirestoreOperation('check_cache', source: Source.cache);
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      await _trackFirestoreOperation('check_cache_error', isOffline: true);
      return false;
    }
  }

  // Batch operations for efficiency
  Future<void> batchUpdateLogs(List<Log> logs) async {
    final batch = _firestore.batch();
    final logIds = <String>[];

    for (final log in logs) {
      if (log.id == null) continue;
      batch.update(_userLogsCollection.doc(log.id), log.toMap());
      logIds.add(log.id!);
    }

    bool isOffline = false;
    try {
      await batch.commit();
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        isOffline = true;
      } else {
        rethrow;
      }
    } finally {
      await _trackFirestoreOperation(
        'batch_update',
        logId: logIds.join(','),
        isOffline: isOffline,
      );
    }
  }

  // For analytics - get total operation counts
  Future<void> trackTotalOperations(
      {required int reads,
      required int writes,
      String period = 'session'}) async {
    try {
      await _analytics.logEvent(
        name: 'firestore_usage_stats',
        parameters: {
          'reads': reads,
          'writes': writes,
          'period': period,
          'user_id': userId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }
  }
}
