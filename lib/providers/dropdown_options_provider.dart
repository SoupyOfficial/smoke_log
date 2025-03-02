import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reason_option.dart';

final dropdownOptionsProvider = StreamProvider<List<ReasonOption>>((ref) {
  final collection = FirebaseFirestore.instance.collection('dropdown_options');
  return collection.orderBy('display_order').snapshots().map((snapshot) =>
      snapshot.docs
          .map((doc) => ReasonOption.fromMap(doc.data(), doc.id))
          .toList());
});
