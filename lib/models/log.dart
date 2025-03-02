import 'package:cloud_firestore/cloud_firestore.dart';

class Log {
  final String? id;
  final DateTime timestamp;
  final String? description;

  Log({
    this.id,
    required this.timestamp,
    this.description,
  });

  factory Log.fromMap(Map<String, dynamic> map, String docId) {
    return Log(
      id: docId,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
    };
  }
}
