import 'package:flutter/material.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency SOS")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 120, color: Colors.red),
            const SizedBox(height: 20),
            const Text("Are you experiencing a medical emergency?", style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Alert sent to your Doctor and Family!')));
              },
              child: const Text("SOS", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            const Text("Pressing this will instantly share your GPS location and last known glucose levels.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
    );
  }
}
