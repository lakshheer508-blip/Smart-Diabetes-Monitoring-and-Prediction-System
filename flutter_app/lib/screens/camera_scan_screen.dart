import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;

  Future<void> _simulateScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    final baseUrl = await ApiService.getBaseUrl();
    final isBackendNode = true; // In full flow, we send to node -> ai_service

    final aiBaseUrl = await ApiService.getAiBaseUrl();

    // Since we don't have real camera connected in emulator without complex setup,
    // we simulate uploading a dummy image.
    try {
      // In practice we'd send bytes. Sending dummy payload to AI service.
      final res = await http.post(
          Uri.parse('$aiBaseUrl/image-analysis'), // Directly to AI for demo
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"image_data": "simulated_base64_string"}));

      if (res.statusCode == 200) {
        setState(() {
          _scanResult = jsonDecode(res.body);
        });
      }
    } catch (e) {
      print("Error scanning: $e");
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("AI Body Scan")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isScanning ? null : _simulateScan,
                child: _isScanning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Upload Photo & Scan"),
              ),
              const SizedBox(height: 30),
              if (_scanResult != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text("Results",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(),
                      Text("Body Type: ${_scanResult!['detected_body_type']}"),
                      Text(
                          "Est Weight: ${_scanResult!['estimated_weight']} kg"),
                      Text("Est BMI: ${_scanResult!['estimated_bmi']}"),
                      Text("Risk: ${_scanResult!['diabetes_risk']}"),
                      const SizedBox(height: 10),
                      const Text("Smart Diet Plan Generated!",
                          style: TextStyle(color: Colors.greenAccent)),
                    ],
                  ),
                )
            ],
          ),
        ));
  }
}
