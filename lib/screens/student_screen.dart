import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final p = context.read<AppProvider>();
    await p.loadStudentsFromFirebase();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            margin:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            child: ListTile(
              title: Text(
                s.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ID: ${s.id} | Class: ${s.studentClass}"),
                  Text("Phone: ${s.phone} | Batch: $batchName"),
                  Text(
                    "Fee: ৳${s.monthlyFee}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
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
                  PopupMenuItem(
                      value: 'assign', child: Text("Assign Month")),
                  PopupMenuItem(
                      value: 'collect', child: Text("Collect Fee")),
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
    final classCtrl =
    TextEditingController(text: student?.studentClass ?? '');
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
            onPressed: () async {
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

              Navigator.pop(context); // ✅ CLOSE FIRST (offline safe)

              if (student == null) {
                await p.addStudent(
                  name: nameCtrl.text.trim(),
                  studentClass: classCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  fee: fee,
                  batchId: batchId!,
                );
              } else {
                await p.updateStudent(
                  id: student.id,
                  name: nameCtrl.text.trim(),
                  studentClass: classCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  fee: fee,
                  batchId: batchId!,
                );
              }
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
            onPressed: () async {
              Navigator.pop(context); // ✅ CLOSE FIRST
              await p.deleteStudent(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------- ASSIGN MONTH ----------
  void _assignMonth(BuildContext context, dynamic student) {
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
          title: Text("Assign Month to ${student.name}"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<int>(
                value: tempMonth,
                items: months
                    .map((m) => DropdownMenuItem(
                  value: m,
                  child:
                  Text(DateFormat.MMMM().format(DateTime(0, m))),
                ))
                    .toList(),
                onChanged: (v) => setState(() => tempMonth = v!),
              ),
              DropdownButton<int>(
                value: tempYear,
                items: years
                    .map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                ))
                    .toList(),
                onChanged: (v) => setState(() => tempYear = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ✅ CLOSE FIRST
                p.assignMonth(
                  studentId: student.id,
                  month: tempMonth,
                  year: tempYear,
                  amount: student.monthlyFee,
                );
              },
              child: const Text("Assign"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- COLLECT FEE ----------
  void _collectFeeDialog(BuildContext context, dynamic student) {
    final p = context.read<AppProvider>();
    final payments = p
        .paymentHistory(student.id)
        .map((e) => Map<String, dynamic>.from(e))
        .where((pmt) => pmt['status'] != 'paid')
        .map((pmt) => DateTime.parse(pmt['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No unpaid months available")),
      );
      return;
    }

    DateTime selectedMonth = payments.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Collect Fee for ${student.name}"),
        content: DropdownButtonFormField<DateTime>(
          value: selectedMonth,
          decoration: const InputDecoration(labelText: "Select Month"),
          items: payments.map((d) {
            final label =
                "${DateFormat.MMM().format(d)}${d.year.toString().substring(2)}";
            return DropdownMenuItem(value: d, child: Text(label));
          }).toList(),
          onChanged: (v) {
            if (v != null) selectedMonth = v;
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ✅ CLOSE FIRST
              p.collectFee(
                student.id,
                student.monthlyFee,
                month: selectedMonth.month,
                year: selectedMonth.year,
              );
            },
            child: const Text("Collect"),
          ),
        ],
      ),
    );
  }
}
