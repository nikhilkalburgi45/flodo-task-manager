// lib/services/api_service.dart
//
// All communication with the Node.js backend goes through this class.
// Nothing else in the app should use http directly.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // 10.0.2.2 = localhost on Android emulator
  // If running on a real device, replace with your computer's local IP
  // e.g. http://192.168.1.5:5000/api
  static const String _baseUrl = 'http://localhost:5000/api';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // ── GET /tasks ──────────────────────────────────────────────────────────────
  // Fetches all tasks. Optionally filter by search term and/or status.
  static Future<List<Task>> getTasks({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status != 'All') queryParams['status'] = status;

    final uri =
        Uri.parse('$_baseUrl/tasks').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'];
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(_extractError(response));
    }
  }

  // ── GET /tasks/:id ──────────────────────────────────────────────────────────
  static Future<Task> getTaskById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception(_extractError(response));
    }
  }

  // ── POST /tasks ─────────────────────────────────────────────────────────────
  // Backend adds a 2-second delay here — our UI shows a loading state during this.
  static Future<Task> createTask(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception(_extractError(response));
    }
  }

  // ── PUT /tasks/:id ──────────────────────────────────────────────────────────
  // Backend adds a 2-second delay here too.
  static Future<Task> updateTask(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception(_extractError(response));
    }
  }

  // ── DELETE /tasks/:id ───────────────────────────────────────────────────────
  static Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response));
    }
  }

  // ── Helper: extract error message from response body ───────────────────────
  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['message'] ?? 'Something went wrong';
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }
}
