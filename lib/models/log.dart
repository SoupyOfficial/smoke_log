import 'package:cloud_firestore/cloud_firestore.dart';

class Log {
  final String? id;
  final DateTime timestamp;
  final int durationSeconds;
  final List<String> reason;
  final int moodRating;
  final int physicalRating;
  final String? notes;
  final int potencyRating;

  Log({
    this.id,
    required this.timestamp,
    this.durationSeconds = 0,
    List<String>? reason,
    this.moodRating = 1,
    this.physicalRating = 1,
    this.notes,
    required this.potencyRating,
  }) : reason = reason ?? [];

  factory Log.fromMap(Map<String, dynamic> map, String docId) {
    return Log(
      id: docId,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] ?? 0,
      reason: map['reason'] is List
          ? List<String>.from(map['reason'])
          : [map['reason'] ?? ''],
      moodRating: (map['moodRating'] ?? 1).toInt(),
      physicalRating: (map['physicalRating'] ?? 1).toInt(),
      notes: map['notes'],
      potencyRating: map['potencyRating'],
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
      'potencyRating': potencyRating,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'potencyRating': potencyRating,
      'reason': reason,
      'moodRating': moodRating,
      'physicalRating': physicalRating,
      'notes': notes,
    };
  }
}
