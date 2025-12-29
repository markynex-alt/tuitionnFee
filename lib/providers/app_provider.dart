import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/batch.dart';
import '../models/student.dart';

class AppProvider extends ChangeNotifier {

  // ✅ LAZY BOX ACCESS (THIS FIXES HiveError)
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

  void addBatch(String name) {
    if (name.trim().isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    batchBox.put(id, {'id': id, 'name': name});
    notifyListeners();
  }
  // ---------- UPDATE BATCH ----------
  void updateBatch(String id, String newName) {
    if (newName.trim().isEmpty) return;
    batchBox.put(id, {'id': id, 'name': newName});
    notifyListeners();
  }

// ---------- DELETE BATCH ----------
  void deleteBatch(String id) {
    batchBox.delete(id);

    // Optional: remove students from this batch
    for (var key in studentBox.keys) {
      final s = studentBox.get(key);
      if (s != null && s['batchId'] == id) {
        studentBox.put(key, {...s, 'batchId': ''});
      }
    }
    notifyListeners();
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

  // ---------- STUDENT ID SETTINGS ----------
  String get studentIdPrefix =>
      settingsBox.get('prefix', defaultValue: 'ST') as String;

  int get studentIdLength =>
      settingsBox.get('length', defaultValue: 5) as int;

  void setStudentIdConfig({
    required String prefix,
    required int length,
  }) {
    settingsBox.put('prefix', prefix);
    settingsBox.put('length', length);
    notifyListeners();
  }

  String generateStudentId() {
    final max = pow(10, studentIdLength) as int;
    final number = Random().nextInt(max)
        .toString()
        .padLeft(studentIdLength, '0');
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
  // ---------- UPDATE STUDENT ----------
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

// ---------- DELETE STUDENT ----------
  void deleteStudent(String id) {
    studentBox.delete(id);
    notifyListeners();
  }

// ---------- GET BATCH NAME ----------
  String batchNameById(String id) {
    final b = batchBox.get(id);
    if (b == null) return 'No Batch';
    return b['name']?.toString() ?? 'No Batch';
  }



  // ---------- PAYMENT ----------
  void collectFee(
      String studentId,
      double amount, {
        int? month,
        int? year,
      }) {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    // 🔒 Prevent duplicate month
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
      // Update existing record
      final p = Map<String, dynamic>.from(paymentBox.get(existingKey));
      p['amount'] = amount;
      p['status'] = amount > 0 ? 'paid' : 'assigned';
      paymentBox.put(existingKey, p);
    } else {
      // Create new record
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
