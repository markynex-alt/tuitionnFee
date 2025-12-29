import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Students")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: p.students.isEmpty
          ? const Center(child: Text("No students added yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: p.students.length,
        itemBuilder: (context, i) {
          final s = p.students[i];
          final batchName = p.batchNameById(s.batchId);

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showAddEditDialog(context, student: s);
                      } else if (v == 'delete') {
                        _deleteStudent(context, s.id);
                      } else if (v == 'assign') {
                        _assignMonth(context, s);
                      } else if (v == 'collect') {
                        _collectFeeDialog(context, s);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text("Edit")),
                      PopupMenuItem(value: 'delete', child: Text("Delete")),
                      PopupMenuItem(value: 'assign', child: Text("Assign Month")),
                      PopupMenuItem(value: 'collect', child: Text("Collect Fee")),
                    ],
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ID: ${s.id} | Class: ${s.studentClass}"),
                  Text("Phone: ${s.phone} | Batch: $batchName"),
                  Text(
                    "Fee: ৳${s.monthlyFee}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- ADD / EDIT ----------
  void _showAddEditDialog(BuildContext context, {dynamic student}) {
    final p = context.read<AppProvider>();

    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final classCtrl = TextEditingController(text: student?.studentClass ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final feeCtrl =
    TextEditingController(text: student?.monthlyFee.toString() ?? '');
    String? batchId = student?.batchId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? "Add Student" : "Edit Student"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: "Class")),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Phone")),
              TextField(
                controller: feeCtrl,
                decoration: const InputDecoration(labelText: "Monthly Fee"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: batchId,
                hint: const Text("Select Batch"),
                items: p.batches
                    .map((b) =>
                    DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => batchId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty ||
                  classCtrl.text.isEmpty ||
                  phoneCtrl.text.isEmpty ||
                  feeCtrl.text.isEmpty ||
                  batchId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              final fee = double.tryParse(feeCtrl.text);
              if (fee == null) return;

              if (student == null) {
                p.addStudent(
                  name: nameCtrl.text.trim(),
                  studentClass: classCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  fee: fee,
                  batchId: batchId!,
                );
              } else {
                p.updateStudent(
                  id: student.id,
                  name: nameCtrl.text.trim(),
                  studentClass: classCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  fee: fee,
                  batchId: batchId!,
                );
              }

              Navigator.pop(context);
            },
            child: Text(student == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  // ---------- DELETE ----------
  void _deleteStudent(BuildContext context, String id) {
    final p = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              p.deleteStudent(id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------- ASSIGN MONTH ----------
  void _assignMonth(BuildContext context, dynamic student) {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Assign Month"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: "Select Month"),
              items: List.generate(12, (i) {
                final month = i + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat.MMM().format(DateTime(0, month))),
                );
              }),
              onChanged: (v) {
                if (v != null) selectedMonth = v;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: "Select Year"),
              items: List.generate(5, (i) => DateTime.now().year + i)
                  .map((y) => DropdownMenuItem(value: y, child: Text("$y")))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedYear = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final p = context.read<AppProvider>();
              p.collectFee(student.id, 0,
                  month: selectedMonth, year: selectedYear);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Month assigned successfully")),
              );
            },
            child: const Text("Assign"),
          ),
        ],
      ),
    );
  }

  // ---------- COLLECT FEE ----------
  void _collectFeeDialog(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
    final amountCtrl = TextEditingController(text: student.monthlyFee.toString());
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final payments = p.paymentHistory(student.id);

    final assignedMonths = payments
        .map((e) => DateTime.parse(e['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (assignedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No months assigned. Assign a month first.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Collect Fee"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              enabled: false,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DateTime>(
              value: assignedMonths.first,
              decoration: const InputDecoration(labelText: "Select Month"),
              items: assignedMonths.map((d) {
                final paid = (payments
                    .firstWhere((pmt) =>
                DateTime.parse(pmt['date']).month == d.month &&
                    DateTime.parse(pmt['date']).year == d.year)['amount'] ??
                    0) >=
                    student.monthlyFee;
                final text = "${DateFormat.MMM().format(d)}${d.year.toString().substring(2)}";
                return DropdownMenuItem(
                  value: d,
                  enabled: !paid,
                  child: Text(
                    text,
                    style: TextStyle(color: paid ? Colors.green : Colors.red),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  selectedMonth = v.month;
                  selectedYear = v.year;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? student.monthlyFee;
              p.collectFee(student.id, amount, month: selectedMonth, year: selectedYear);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fee collected successfully")),
              );
            },
            child: const Text("Collect"),
          ),
        ],
      ),
    );
  }
}
