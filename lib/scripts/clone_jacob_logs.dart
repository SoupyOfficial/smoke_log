import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:smoke_log/firebase_options.dart';

Future<void> cloneJacobLogsToTestUser(String testUserId) async {
  final firestore = FirebaseFirestore.instance;

  // Read all documents from the production "JacobLogs" collection.
  final jacobSnapshot = await firestore.collection('JacobLogs').get();

  // Reference to the test user's logs collection.
  final testLogsRef =
      firestore.collection('users').doc(testUserId).collection('logs');

  // Start a write batch.
  final batch = firestore.batch();

  // Delete existing documents in the test user's logs collection.
  final existingLogs = await testLogsRef.get();
  for (var doc in existingLogs.docs) {
    batch.delete(doc.reference);
  }

  // For each document in JacobLogs, map 'length' to 'durationSeconds'
  // and add a 'notes' field if not already present.
  for (var doc in jacobSnapshot.docs) {
    final data = doc.data();
    // Convert 'length' to an integer for durationSeconds.
    final durationSeconds = (data['length'] ?? 0).toInt();
    // Use the existing notes field if present, otherwise add a default note.
    final notes =
        data.containsKey('notes') ? data['notes'] : 'Cloned from JacobLogs';

    // Prepare the new log data.
    final newLogData = {
      'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
      'durationSeconds': durationSeconds,
      'reason': data['reason'] ?? '',
      'moodRating': data['moodRating'] ?? 0.0,
      'physicalRating': data['physicalRating'] ?? 0.0,
      'notes': notes,
      'potencyRating': data['potencyRating'] ?? 0,
    };

    // Use the same document id (or generate a new one as needed).
    batch.set(testLogsRef.doc(doc.id), newLogData, SetOptions(merge: true));
  }

  // Commit all batched writes.
  await batch.commit();
  print(
      'Cloned ${jacobSnapshot.docs.length} documents to user $testUserId logs.');
}

Future<void> main(List<String> args) async {
  // Expect the test user ID as a command line argument.
  if (args.isEmpty) {
    // print('Usage: dart run lib/scripts/clone_jacob_logs.dart <testUserId>');
    // exit(1);

    args.add('1Wu1BALZOiXlGHtzuVgCEic0Ecw1');
  }

  final testUserId = args.first;

  // Initialize Flutter bindings and Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await cloneJacobLogsToTestUser(testUserId);
}
