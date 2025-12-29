import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


import '../providers/app_provider.dart';

class BatchScreen extends StatelessWidget {
  const BatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Batches")),
      body: p.batches.isEmpty
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
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editBatch(context, batch.id, batch.name);
                    } else if (value == 'delete') {
                      _deleteBatch(context, batch.id);
                    } else if (value == 'assign') {
                      _assignMonth(context, batch.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text("Edit")),
                    PopupMenuItem(value: 'delete', child: Text("Delete")),
                    PopupMenuItem(value: 'assign', child: Text("Assign Month")), // new option
                  ],
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
            onPressed: () {
              p.addBatch(ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------- EDIT BATCH ----------
  void _editBatch(BuildContext context, String id, String oldName) {
    final ctrl = TextEditingController(text: oldName);
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Batch"),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              p.updateBatch(id, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ---------- DELETE BATCH ----------
  void _deleteBatch(BuildContext context, String id) {
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Batch"),
        content: const Text("Are you sure? Students will be unassigned."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              p.deleteBatch(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  // ---------- ASSIGN MONTH ----------
  void _assignMonth(BuildContext context, String batchId) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign Month"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month selector
            DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: "Select Month"),
              items: List.generate(12, (i) {
                final month = i + 1;
                final monthName =
                DateFormat.MMM().format(DateTime(0, month));
                return DropdownMenuItem(
                  value: month,
                  child: Text(monthName),
                );
              }),
              onChanged: (v) {
                if (v != null) selectedMonth = v;
              },
            ),
            const SizedBox(height: 12),

            // Year selector
            DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: "Select Year"),
              items: List.generate(5, (i) {
                final year = DateTime.now().year + i;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (v) {
                if (v != null) selectedYear = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final p = context.read<AppProvider>();
              final students = p.studentsByBatch(batchId);

              for (final s in students) {
                // ✅ ALWAYS assign (collectFee handles duplicates)
                p.collectFee(
                  s.id,
                  0, // 0 = assigned
                  month: selectedMonth,
                  year: selectedYear,
                );
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Month assigned successfully"),
                ),
              );
            },
            child: const Text("Assign"),
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
        final students =
        context.read<AppProvider>().studentsByBatch(batchId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Students in $name",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
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
                      subtitle: Text("ID: ${s.id} | Fee: ৳${s.monthlyFee}"),
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
