import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController prefixCtrl;
  late TextEditingController lengthCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    prefixCtrl = TextEditingController(text: p.studentIdPrefix);
    lengthCtrl = TextEditingController(text: p.studentIdLength.toString());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: prefixCtrl,
                decoration:
                    const InputDecoration(labelText: "Student ID Prefix")),
            TextField(
                controller: lengthCtrl,
                decoration:
                    const InputDecoration(labelText: "Student ID Length (5-6)"),
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final len = int.tryParse(lengthCtrl.text);
                if (len == null || (len != 5 && len != 6)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Length must be 5 or 6")));
                  return;
                }
                p.setStudentIdConfig(
                    prefix: prefixCtrl.text.trim(), length: len);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings saved")));
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
