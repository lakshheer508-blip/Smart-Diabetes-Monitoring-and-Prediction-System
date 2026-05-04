import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMsg = '';

  void _register() async {
    setState(() { _isLoading = true; _errorMsg = ''; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(_nameController.text, _emailController.text, _passwordController.text);
    if (!success) {
      setState(() { _errorMsg = 'Registration failed. Email might exist.'; _isLoading = false; });
    } else {
      Navigator.pop(context); // Go back to login/dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 60, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text("Join GlucoSense", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const SizedBox(height: 32),
                if (_errorMsg.isNotEmpty) ...[
                  Text(_errorMsg, style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
