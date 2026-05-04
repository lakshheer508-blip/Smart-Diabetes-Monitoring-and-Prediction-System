import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  void _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('backend_ip') ?? '';
    });
  }

  void _saveIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_ip', _ipController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IP Saved Successfully")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Settings'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Since the app is running on your mobile device, please enter your computer's local Wi-Fi IP Address (e.g. 192.168.1.5) so the app can connect to the Python Backend.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IPv4 Address',
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
                onPressed: _saveIp,
                child: const Text('Save Configure', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
