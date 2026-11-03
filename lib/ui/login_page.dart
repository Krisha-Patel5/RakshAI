import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/permission_service.dart';
import 'main_navigation.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  // Updated login logic to handle Supabase Authentication and Profile Sync
  Future<void> _handleLogin() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Sign in with Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (response.user != null) {
        final data = await supabase
            .from('profiles')
            .select('user_phone')
            .eq('id', response.user!.id)
            .single();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', data['user_phone'] ?? "");
        await prefs.setString('user_email', response.user!.email ?? "");

        debugPrint(" Login successful. Phone synced: ${data['user_phone']}");

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Login Info"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    PermissionService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.shield, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("RakshAI",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                  controller: email,
                  decoration: const InputDecoration(
                    hintText: "Email / Username",
                    border: OutlineInputBorder(),
                  )),
              const SizedBox(height: 20),
              TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(),
                  )),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: _handleLogin, child: const Text("LOGIN")),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  );
                },
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}