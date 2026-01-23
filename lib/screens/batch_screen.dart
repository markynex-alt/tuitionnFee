import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking internet
import '../providers/app_provider.dart';
import '../models/batch.dart';
import 'student_screen.dart';
import 'package:intl/intl.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncBatches();
  }

  Future<void> _syncBatches() async {
    // Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      setState(() => isLoading = true);
      await context.read<AppProvider>().loadBatchesFromFirebase();
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Batches")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : p.batches.isEmpty
          ? const Center(child: Text("No batches created"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: p.batches.length,
        itemBuilder: (context, index) {
          final batch = p.batches[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                _openBatchStudents(context, batch.id, batch.name);
              },
              child: ListTile(
                title: Text(batch.name),
                subtitle: Text(
                  "Students: ${p.studentsByBatch(batch.id).length}",
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBatch(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------- ADD BATCH ----------
  void _addBatch(BuildContext context) {
    final ctrl = TextEditingController();
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Batch"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "Batch name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              p.addBatch(ctrl.text);
              Navigator.pop(context);
              // Sync with Firebase after adding
              await _syncBatches();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------- VIEW STUDENTS UNDER BATCH ----------
  void _openBatchStudents(BuildContext context, String batchId, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final students = context.read<AppProvider>().studentsByBatch(batchId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Students in $name",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              students.isEmpty
                  ? const Text("No students in this batch")
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  return Card(
                    child: ListTile(
                      title: Text(s.name),
                      subtitle:
                      Text("ID: ${s.id} | Fee: ৳${s.monthlyFee}"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
