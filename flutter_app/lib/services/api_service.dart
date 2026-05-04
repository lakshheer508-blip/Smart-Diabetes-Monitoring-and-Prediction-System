import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiService {
  static Future<String> getBaseUrl() async {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  static Future<String> getAiBaseUrl() async {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ──────────────── LOGIN ────────────────
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      print("Attempting login to: $baseUrl/auth/login with email: $email");
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));

      print("Login response status: ${res.statusCode}");
      print("Login response body: ${res.body}");

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        await prefs.setString('user_role', data['role'] ?? 'Patient');
        return data;
      } else {
        print("Login failed: ${data['message'] ?? 'Unknown error'}");
        return {'error': data['message'] ?? 'Invalid email or password'};
      }
    } catch (e) {
      print("Login error: $e");
      return {
        'error':
            'Cannot connect to server. Make sure backend is running on port 5000.'
      };
    }
  }

  // ──────────────── REGISTER ────────────────
  static Future<Map<String, dynamic>> register(
      String name, String email, String password,
      {String role = 'Patient',
      int age = 30,
      double weight = 70.0,
      String diabetesType = 'Type 2'}) async {
    final baseUrl = await getBaseUrl();
    try {
      print("Attempting register to: $baseUrl/auth/register");
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
              "role": role,
              "age": age,
              "weight": weight,
              "diabetes_type": diabetesType
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("Register response status: ${res.statusCode}");
      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      print("Register error: $e");
      return {'success': false, 'error': 'Cannot connect to server.'};
    }
  }

  // ──────────────── HEALTH LOGS ────────────────
  static Future<List<dynamic>> getHealthLogs() async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/data/get_health_logs'),
              headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Logs error: $e");
    }
    return [];
  }

  // ──────────────── PREDICTIONS ────────────────
  static Future<Map<String, dynamic>?> getPredictions() async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/data/get_predictions'),
              headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Preds error: $e");
    }
    return null;
  }

  // ──────────────── WEEKLY PREDICTIONS ────────────────
  static Future<Map<String, dynamic>?> getWeeklyPredictions() async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/data/get_weekly_predictions'),
              headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Weekly preds error: $e");
    }
    return null;
  }

  // ──────────────── REPORTS ────────────────
  static Future<Map<String, dynamic>?> getReports() async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/data/get_reports'),
              headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Reports error: $e");
    }
    return null;
  }

  // ──────────────── LOG HEALTH DATA ────────────────
  static Future<bool> logHealthData(Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/data/log_health_data'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("Log health data error: $e");
    }
    return false;
  }

  // ──────────────── DIET PLAN ────────────────
  static Future<Map<String, dynamic>> getDietPlan({double? bmi}) async {
    final baseUrl = await getBaseUrl();
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/data/diet-plan'),
            headers: await _getHeaders(),
            body: jsonEncode({
              if (bmi != null) "bmi": bmi,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = res.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(res.body) as Map)
          : <String, dynamic>{};
      if (res.statusCode == 200) {
        return {'success': true, ...data};
      }

      return {
        'success': false,
        'error': data['detail'] ??
            data['message'] ??
            'Unable to generate diet plan.',
      };
    } catch (e) {
      print("Diet plan error: $e");
      return {
        'success': false,
        'error':
            'Cannot connect to server. Make sure backend and AI service are running.',
      };
    }
  }
}
