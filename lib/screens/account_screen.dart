import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../models/student.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  Student? foundStudent;

  // ---------- INIT ----------
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AppProvider>();
      p.loadPaymentsFromFirebase();
      p.syncPaymentsToFirebase();
    });
  }

  // ---------- SEARCH ----------
  void searchStudent(AppProvider p) {
    final q = searchCtrl.text.trim().toLowerCase();
    foundStudent = p.students.firstWhereOrNull(
          (s) =>
      s.id.toLowerCase().contains(q) ||
          s.name.toLowerCase().contains(q) ||
          s.phone.contains(q),
    );
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  // ---------- COLLECT FEE ----------
  void _collectFeeDialog(AppProvider p, Student student) {
    final payments = p.paymentHistory(student.id);

    // ✅ Convert all maps to proper Map<String, dynamic>
    final assignedMonths = payments
        .map((e) => Map<String, dynamic>.from(e))
        .where((pmt) => pmt['status'] != 'paid') // only unpaid
        .map((pmt) => DateTime.parse(pmt['date']))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (assignedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No unpaid months available")),
      );
      return;
    }

    final amountCtrl =
    TextEditingController(text: student.monthlyFee.toString());
    DateTime selectedMonth = assignedMonths.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Collect Fee"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                enabled: false,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DateTime>(
                value: selectedMonth,
                decoration: const InputDecoration(labelText: "Select Month"),
                items: assignedMonths.map((d) {
                  final monthYear =
                      "${DateFormat.MMM().format(d)}${d.year.toString().substring(2)}";
                  return DropdownMenuItem<DateTime>(
                    value: d,
                    child: Text(monthYear),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) selectedMonth = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount != null) {
                p.collectFee(student.id, amount,
                    month: selectedMonth.month, year: selectedMonth.year);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fee collected successfully")),
                );
                setState(() {});
              }
            },
            child: const Text("Collect"),
          ),
        ],
      ),
    );
  }

  // ---------- PAYMENT CALENDAR ----------
  Widget _paymentCalendar(AppProvider p, Student student) {
    final payments = p.paymentHistory(student.id)
        .map((e) => Map<String, dynamic>.from(e)) // fix type
        .toList();

    if (payments.isEmpty) {
      return const Text("No months assigned yet");
    }

    payments.sort((a, b) =>
        DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final record = payments[index];
          final date = DateTime.parse(record['date']);
          final monthYear =
              "${DateFormat.MMM().format(date)}${date.year.toString().substring(2)}";
          final isPaid = record['status'] == 'paid';
          final amount = (record['amount'] ?? 0).toDouble();
          final firebaseId = record['id'] ?? "N/A"; // ✅ Firebase payment ID

          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.shade400 : Colors.red.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              "$monthYear\n৳${amount.toInt()}\nID:$firebaseId", // show Firebase ID
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- STUDENT CARD ----------
  Widget _studentCard(Student s, AppProvider p) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("ID: ${s.id}"),
          Text("Class: ${s.studentClass}"),
          Text("Phone: ${s.phone}"),
          Text("Batch: ${p.batchNameById(s.batchId)}"),
          const SizedBox(height: 8),
          Text("Monthly Fee: ৳${s.monthlyFee}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        ]),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Student Account")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchStudent(p),
                decoration: InputDecoration(
                  hintText: "Search by ID / Name / Phone",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => searchStudent(p),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              if (foundStudent != null) ...[
                _studentCard(foundStudent!, p),
                const SizedBox(height: 16),
                const Text("Payment Calendar",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _paymentCalendar(p, foundStudent!),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text("Collect Fee"),
                  onPressed: () => _collectFeeDialog(p, foundStudent!),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      "Search student to view account",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
