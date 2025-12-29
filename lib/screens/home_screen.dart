import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _statCard(
              title: 'Students',
              value: p.students.length.toString(),
              icon: Icons.school,
              color: Colors.blue,
            ),
            _statCard(
              title: 'Batches',
              value: p.batches.length.toString(),
              icon: Icons.groups,
              color: Colors.orange,
            ),
            _statCard(
              title: 'Total Income',
              value: '৳${p.totalIncome}',
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
            _statCard(
              title: 'Payments',
              value: p.paymentBox.length.toString(),
              icon: Icons.receipt_long,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
