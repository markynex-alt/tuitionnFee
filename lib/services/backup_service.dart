import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class BackupService {
  static Future<void> backup() async {
    final firestore = FirebaseFirestore.instance;
    final students = Hive.box('students').values;
    final batches = Hive.box('batches').values;

    for (var b in batches) {
      await firestore.collection('batches').doc(b['id']).set(b);
    }
    for (var s in students) {
      await firestore.collection('students').doc(s['id']).set(s);
    }
  }
}
