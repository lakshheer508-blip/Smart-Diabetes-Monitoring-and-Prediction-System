import 'package:flutter/material.dart';

class DoctorPanelScreen extends StatefulWidget {
  const DoctorPanelScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPanelScreen> createState() => _DoctorPanelScreenState();
}

class _DoctorPanelScreenState extends State<DoctorPanelScreen> {
  final List<Map<String, dynamic>> patients = [
    {"name": "John Doe", "risk": "High", "last_glucose": 185},
    {"name": "Alice Smith", "risk": "Low", "last_glucose": 105},
    {"name": "Ravi Kumar", "risk": "Moderate", "last_glucose": 130},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Doctor Dashboard")),
        body: ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final p = patients[index];
            final color = p['risk'] == 'High'
                ? Colors.redAccent
                : (p['risk'] == 'Moderate'
                    ? Colors.orangeAccent
                    : Colors.greenAccent);
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(p['name']),
              subtitle: Text(
                  "Risk: ${p['risk']}  |  Last Glucose: ${p['last_glucose']}"),
              trailing: IconButton(
                icon: const Icon(Icons.message, color: Colors.blueAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message sent to ${p["name"]}!')));
                },
              ),
              tileColor: color.withOpacity(0.1),
            );
          },
        ));
  }
}
