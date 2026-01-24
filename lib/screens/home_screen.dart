import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final now = DateTime.now();

    final payments = p.paymentBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final paid = payments.where((e) => e['status'] == 'paid').toList();
    final assigned = payments.where((e) => e['status'] == 'assigned').toList();

    double sum(List<Map<String, dynamic>> list) =>
        list.fold(0.0, (s, e) => s + (e['amount'] ?? 0));

    double currentMonthSum(List<Map<String, dynamic>> list) => list
        .where((e) {
      final d = DateTime.parse(e['date']);
      return d.month == now.month && d.year == now.year;
    })
        .fold(0.0, (s, e) => s + (e['amount'] ?? 0));

    final totalIncome = sum(paid);
    final totalDue = sum(assigned);
    final monthIncome = currentMonthSum(paid);
    final monthDue = currentMonthSum(assigned);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ================= UNIFORM STAT CARDS =================
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _statTile(
                  title: 'Students',
                  value: p.students.length.toString(),
                  icon: Icons.school,
                  color: Colors.blue,
                ),
                _statTile(
                  title: 'Batches',
                  value: p.batches.length.toString(),
                  icon: Icons.groups,
                  color: Colors.orange,
                ),
                _statTile(
                  title: 'Total Income',
                  value: '৳${totalIncome.toStringAsFixed(0)}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                _statTile(
                  title: 'Total Due',
                  value: '৳${totalDue.toStringAsFixed(0)}',
                  icon: Icons.warning_amber,
                  color: Colors.red,
                ),
                _statTile(
                  title: 'This Month Income',
                  value: '৳${monthIncome.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: Colors.teal,
                ),
                _statTile(
                  title: 'This Month Due',
                  value: '৳${monthDue.toStringAsFixed(0)}',
                  icon: Icons.schedule,
                  color: Colors.deepOrange,
                ),
                _statTile(
                  title: 'Overall Paid',
                  value: '৳${totalIncome.toStringAsFixed(0)}',
                  icon: Icons.check_circle,
                  color: Colors.indigo,
                ),
                _statTile(
                  title: 'Overall Assigned',
                  value: '৳${totalDue.toStringAsFixed(0)}',
                  icon: Icons.assignment,
                  color: Colors.brown,
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// ================= PIE CHART =================
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Payment Distribution',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 50,
                          sections: [
                            PieChartSectionData(
                              value: paid.length.toDouble(),
                              title: 'Paid',
                              color: Colors.green,
                              radius: 60,
                            ),
                            PieChartSectionData(
                              value: assigned.length.toDouble(),
                              title: 'Due',
                              color: Colors.red,
                              radius: 60,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// ================= RECENT PAID =================
            _tableCard(
              title: 'Recent Paid Fees',
              headers: const ['Student', 'Amount', 'Month'],
              rows: paid.take(5).map((e) {
                final d = DateTime.parse(e['date']);
                return [
                  e['studentId'].toString(),
                  '৳${e['amount']}',
                  '${d.month}/${d.year}',
                ];
              }).toList(),
            ),

            const SizedBox(height: 24),

            /// ================= RECENT DUE =================
            _tableCard(
              title: 'Recent Due Fees',
              headers: const ['Student', 'Amount', 'Month'],
              rows: assigned.take(5).map((e) {
                final d = DateTime.parse(e['date']);
                return [
                  e['studentId'].toString(),
                  '৳${e['amount']}',
                  '${d.month}/${d.year}',
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UNIFORM STAT TILE =================
  Widget _statTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22, color: color),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TABLE CARD =================
  Widget _tableCard({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns:
                headers.map((h) => DataColumn(label: Text(h))).toList(),
                rows: rows
                    .map(
                      (r) => DataRow(
                    cells:
                    r.map((c) => DataCell(Text(c))).toList(),
                  ),
                )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
