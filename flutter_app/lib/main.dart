import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/weekly_prediction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/camera_scan_screen.dart' as camera_scan;
import 'screens/diet_plan_screen.dart' as diet_plan;
import 'screens/doctor_panel_screen.dart' as doctor_panel;
import 'screens/sos_screen.dart' as sos;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SmartDiabetesApp(),
    ),
  );
}

class SmartDiabetesApp extends StatelessWidget {
  const SmartDiabetesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlucoSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),

      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return auth.isAuthenticated ? const DashboardScreen() : const LoginScreen();
        },
      ),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/weekly_prediction': (context) => const WeeklyPredictionScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/camera_scan': (context) => const camera_scan.CameraScanScreen(),
        '/diet_plan': (context) => const diet_plan.DietPlanScreen(),
        '/doctor_panel': (context) => const doctor_panel.DoctorPanelScreen(),
        '/sos': (context) => const sos.SOSScreen(),
      },
    );
  }
}