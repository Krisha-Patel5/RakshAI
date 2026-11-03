import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();


  final _formKey = GlobalKey<FormState>();


  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        final prefs = await SharedPreferences.getInstance();

        final authResponse = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = authResponse.user;

        if (user != null) {
          await supabase.from('profiles').insert({
            'id': user.id,
            'user_phone': phoneController.text.trim(),
            'user_email': emailController.text.trim(),
          });




          await prefs.setString('user_email', emailController.text.trim());
          await prefs.setString('user_password', passwordController.text.trim());
          await prefs.setString('user_phone', phoneController.text.trim());
          await prefs.setString('user_name', nameController.text.trim());

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Created Successfully!"),
              backgroundColor: Colors.green,
            ),
          );


          Navigator.pop(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signup Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.person_add_alt_1, size: 80, color: Colors.blue),
                const SizedBox(height: 30),


                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => !value!.contains("@") ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter your phone number" : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.length < 6 ? "Password must be 6+ characters" : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    child: const Text("SIGN UP"),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}