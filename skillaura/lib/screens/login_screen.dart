import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'women_dashboard.dart';
import 'recruiter_dashboard.dart';
import 'admin_dashboard.dart';
import 'user_type_selection.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedUserType = 'Women User'; // Default user type

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Login failed / ലോഗിൻ പരാജയപ്പെട്ടു";
      });
    }

    setState(() => _isLoading = false);
  }

  void _navigateToDashboard() {
    Widget dashboardScreen;

    if (_selectedUserType == 'Women User') {
      dashboardScreen = WomenDashboard();
    } else if (_selectedUserType == 'Recruiter') {
      dashboardScreen = RecruiterDashboard();
    } else {
      dashboardScreen = AdminDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => dashboardScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / ലോഗിൻ'),
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.blue),
                const SizedBox(height: 20),

                // User Type Selection Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    labelText: 'Select User Type / ഉപയോക്തൃ തരം തിരഞ്ഞെടുക്കുക',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    {'english': 'Women User', 'malayalam': 'സ്ത്രീ ഉപയോക്താവ്'},
                    {'english': 'Recruiter', 'malayalam': ''},
                    {'english': 'Admin', 'malayalam': 'അഡ്മിൻ'}
                  ]
                      .map((type) => DropdownMenuItem(
                            value: type['english'],
                            child: Text('${type['english']} / ${type['malayalam']}'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUserType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email / ഇമെയിൽ',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password / പാസ്‌വേഡ്',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login / ലോഗിൻ'),
                ),
                const SizedBox(height: 20),

                // Register Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UserTypeSelection()),
                        );
                      },
                      child: const Text('Register/രജിസ്റ്റർ ചെയ്യുക'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
