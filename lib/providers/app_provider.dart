import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/batch.dart';
import '../models/student.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Box get batchBox => Hive.box('batches');
  Box get studentBox => Hive.box('students');
  Box get paymentBox => Hive.box('payments');
  Box get settingsBox => Hive.box('settings');

  // ---------- BATCH ----------
  List<Batch> get batches => batchBox.values.map((e) {
    final m = Map<String, dynamic>.from(e);
    return Batch(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
    );
  }).toList();

  // ---------- ADD BATCH ----------
  Future<void> addBatch(String name) async {
    if (name.trim().isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final batchData = {'id': id, 'name': name};

    batchBox.put(id, batchData);
    notifyListeners();

    await _saveBatchesToFirebase();
  }

  // ---------- UPDATE BATCH ----------
  Future<void> updateBatch(String id, String newName) async {
    if (newName.trim().isEmpty) return;
    batchBox.put(id, {'id': id, 'name': newName});
    notifyListeners();

    await _saveBatchesToFirebase();
  }

  // ---------- DELETE BATCH ----------
  Future<void> deleteBatch(String id) async {
    batchBox.delete(id);

    // Optional: remove batchId from students
    for (var key in studentBox.keys) {
      final s = studentBox.get(key);
      if (s != null && s['batchId'] == id) {
        studentBox.put(key, {...s, 'batchId': ''});
      }
    }
    notifyListeners();

    await _saveBatchesToFirebase();
  }

  // ---------- SAVE BATCHES TO FIREBASE ----------
  Future<void> _saveBatchesToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final batchList = batches.map((b) => {'id': b.id, 'name': b.name}).toList();

    try {
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(user.email)
          .set({'batches': batchList});
    } catch (e) {
      debugPrint("Error saving batches to Firebase: $e");
    }
  }

  // ---------- LOAD BATCHES FROM FIREBASE ----------
  Future<void> loadBatchesFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('batches')
          .doc(user.email)
          .get();

      if (!doc.exists || doc.data() == null) return;

      final batchList = List<Map<String, dynamic>>.from(doc.data()!['batches'] ?? []);

      await batchBox.clear();
      for (var b in batchList) {
        batchBox.put(b['id'], b);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading batches from Firebase: $e");
    }
  }

  // ---------- STUDENTS BY BATCH ----------
  List<Student> studentsByBatch(String batchId) {
    return students.where((s) => s.batchId == batchId).toList();
  }

  // ---------- STUDENT ----------
  List<Student> get students => studentBox.values.map((e) {
    final m = Map<String, dynamic>.from(e);
    return Student(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
      studentClass: m['class'] ?? '',
      phone: m['phone'] ?? '',
      monthlyFee: (m['fee'] ?? 0).toDouble(),
      batchId: m['batchId'] ?? '',
    );
  }).toList();

  // ------------------- OTHER STUDENT & PAYMENT METHODS -------------------
  String get studentIdPrefix =>
      settingsBox.get('prefix', defaultValue: 'ST') as String;

  int get studentIdLength =>
      settingsBox.get('length', defaultValue: 5) as int;

  void setStudentIdConfig({required String prefix, required int length}) {
    settingsBox.put('prefix', prefix);
    settingsBox.put('length', length);
    notifyListeners();
  }

  String generateStudentId() {
    final max = pow(10, studentIdLength) as int;
    final number = Random().nextInt(max).toString().padLeft(studentIdLength, '0');
    return '$studentIdPrefix$number';
  }

  void addStudent({
    required String name,
    required String studentClass,
    required String phone,
    required double fee,
    required String batchId,
  }) {
    final id = generateStudentId();
    studentBox.put(id, {
      'id': id,
      'name': name,
      'class': studentClass,
      'phone': phone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
  }

  void updateStudent({
    required String id,
    required String name,
    required String studentClass,
    required String phone,
    required double fee,
    required String batchId,
  }) {
    studentBox.put(id, {
      'id': id,
      'name': name,
      'class': studentClass,
      'phone': phone,
      'fee': fee,
      'batchId': batchId,
    });
    notifyListeners();
  }

  void deleteStudent(String id) {
    studentBox.delete(id);
    notifyListeners();
  }

  String batchNameById(String id) {
    final b = batchBox.get(id);
    if (b == null) return 'No Batch';
    return b['name']?.toString() ?? 'No Batch';
  }

  void collectFee(String studentId, double amount, {int? month, int? year}) {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    final existingKey = paymentBox.keys.firstWhere(
          (k) {
        final p = paymentBox.get(k);
        if (p == null || p['studentId'] != studentId) return false;
        final d = DateTime.parse(p['date']);
        return d.month == m && d.year == y;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      final p = Map<String, dynamic>.from(paymentBox.get(existingKey));
      p['amount'] = amount;
      p['status'] = amount > 0 ? 'paid' : 'assigned';
      paymentBox.put(existingKey, p);
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      paymentBox.put(id, {
        'id': id,
        'studentId': studentId,
        'amount': amount,
        'status': amount > 0 ? 'paid' : 'assigned',
        'date': DateTime(y, m, 1).toIso8601String(),
      });
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> paymentHistory(String studentId) {
    return paymentBox.values
        .where((e) => e['studentId'] == studentId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double get totalIncome =>
      paymentBox.values.fold(0.0, (sum, e) => sum + (e['amount'] ?? 0));
}
