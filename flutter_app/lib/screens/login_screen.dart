import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMsg = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() { _isLoading = true; _errorMsg = ''; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!success) {
      if (mounted) {
        setState(() { _errorMsg = auth.errorMessage; _isLoading = false; });
      }
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Dark slate
                  Color(0xFF1E1B4B), // Deep indigo
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // Decorative glowing orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.15),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.15),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo / Icon with glowing effect
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent.withOpacity(0.1),
                              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 20)]
                            ),
                            child: const Icon(Icons.monitor_heart_outlined, size: 60, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "GlucoSense", 
                            style: TextStyle(
                              fontSize: 32, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white,
                              letterSpacing: 1.2
                            )
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Welcome back. Let's manage your health.", 
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          if (_errorMsg.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 32),
                          
                          // Login Button
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.purpleAccent],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))
                              ]
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(color: Colors.white.withOpacity(0.6))),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/register'),
                                child: const Text("Create one", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
