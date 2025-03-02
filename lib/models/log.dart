import 'package:cloud_firestore/cloud_firestore.dart';

class Log {
  final String? id;
  final DateTime timestamp;
  final int durationSeconds;
  final String reason;
  final double moodRating;
  final double physicalRating;
  final String? notes;

  Log({
    this.id,
    required this.timestamp,
    this.durationSeconds = 0,
    this.reason = '',
    this.moodRating = 0.0,
    this.physicalRating = 0.0,
    this.notes,
  });

  factory Log.fromMap(Map<String, dynamic> map, String docId) {
    return Log(
      id: docId,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] ?? 0,
      reason: map['reason'] ?? '',
      moodRating: (map['moodRating'] ?? 0.0).toDouble(),
      physicalRating: (map['physicalRating'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': durationSeconds,
      'reason': reason,
      'moodRating': moodRating,
      'physicalRating': physicalRating,
      'notes': notes,
    };
  }
}
