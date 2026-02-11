import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/app_provider.dart';
import '../models/batch.dart';
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
            child: ListTile(
              title: Text(batch.name),
              subtitle: Text(
                "Students: ${p.studentsByBatch(batch.id).length}",
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'assign_month') {
                    _assignMonthDialog(batch);
                  } else if (value == 'edit') {
                    _editBatchDialog(batch);
                  } else if (value == 'delete') {
                    _deleteBatchDialog(batch);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'assign_month',
                    child: Text("Assign Month"),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text("Edit"),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              onTap: () => _openBatchStudents(batch),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBatchDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------- ADD BATCH ----------
  void _addBatchDialog() {
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
              if (ctrl.text.trim().isEmpty) return;

              Navigator.pop(context);
              await p.addBatch(ctrl.text.trim());
              await _syncBatches();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------- EDIT BATCH ----------
  void _editBatchDialog(Batch batch) {
    final ctrl = TextEditingController(text: batch.name);
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Batch"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: "Batch name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;

              Navigator.pop(context);
              await p.updateBatch(batch.id, ctrl.text.trim());
              await _syncBatches();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ---------- DELETE BATCH ----------
  void _deleteBatchDialog(Batch batch) {
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Batch"),
        content: Text(
          "Are you sure you want to delete '${batch.name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await p.deleteBatch(batch.id);
              await _syncBatches();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------- VIEW STUDENTS (FIXED) ----------
  void _openBatchStudents(Batch batch) {
    final students =
    context.read<AppProvider>().studentsByBatch(batch.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Students in ${batch.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              students.isEmpty
                  ? const Expanded(
                child: Center(
                  child: Text("No students in this batch"),
                ),
              )
                  : Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          "ID: ${s.id} | Fee: ৳${s.monthlyFee}",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- ASSIGN MONTH ----------
  void _assignMonthDialog(Batch batch) {
    final p = context.read<AppProvider>();
    DateTime now = DateTime.now();
    int tempMonth = now.month;
    int tempYear = now.year;

    final years = List.generate(14, (i) => 2022 + i);
    final months = List.generate(12, (i) => i + 1);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Assign Month to ${batch.name}"),
          content: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<int>(
                value: tempMonth,
                items: months
                    .map(
                      (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      DateFormat.MMMM()
                          .format(DateTime(0, m)),
                    ),
                  ),
                )
                    .toList(),
                onChanged: (v) =>
                    setState(() => tempMonth = v!),
              ),
              DropdownButton<int>(
                value: tempYear,
                items: years
                    .map(
                      (y) => DropdownMenuItem(
                    value: y,
                    child: Text(y.toString()),
                  ),
                )
                    .toList(),
                onChanged: (v) =>
                    setState(() => tempYear = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                p.assignMonthToBatch(
                  batch.id,
                  month: tempMonth,
                  year: tempYear,
                );
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Month assigned successfully"),
                  ),
                );
              },
              child: const Text("Assign"),
            ),
          ],
        ),
      ),
    );
  }
}
