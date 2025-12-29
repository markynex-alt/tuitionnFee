import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final userCredential = await _auth.signInWithProvider(GoogleAuthProvider());
      print("Google login success: ${userCredential.user?.email}");
    } catch (e) {
      print("Google login error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user == null)
              ElevatedButton(
                onPressed: _loginWithGoogle,
                child: const Text("Login with Google"),
              )
            else ...[
              Text(user.email ?? ""),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _logout,
                child: const Text("Logout"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
