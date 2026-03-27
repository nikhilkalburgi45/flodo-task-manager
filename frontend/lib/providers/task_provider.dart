// lib/providers/task_provider.dart
//
// Think of this as the "store" for all task data.
// Any screen that needs tasks listens to this provider.
// When data changes here, all listening screens rebuild automatically.
//
// This is similar to Redux in React — but much simpler.

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isSaving = false; // Separate flag for create/update (2s delay)
  String? _error;

  // Search and filter state
  String _searchQuery = '';
  String _statusFilter = 'All';

  // ── Getters ─────────────────────────────────────────────────────────────────
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // ── Load all tasks ───────────────────────────────────────────────────────────
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Tells all widgets listening to rebuild

    try {
      _tasks = await ApiService.getTasks(
        search: _searchQuery,
        status: _statusFilter,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Search ───────────────────────────────────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
    loadTasks(); // Re-fetch with new search term
  }

  // ── Filter by status ─────────────────────────────────────────────────────────
  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
    loadTasks();
  }

  // ── Create task ──────────────────────────────────────────────────────────────
  // Returns true on success, false on failure.
  // Sets _isSaving = true during the 2-second backend delay.
  Future<bool> createTask(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await ApiService.createTask(data);
      _tasks.insert(0, newTask); // Add to top of list
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── Update task ──────────────────────────────────────────────────────────────
  Future<bool> updateTask(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTask = await ApiService.updateTask(id, data);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) _tasks[index] = updatedTask;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete task ──────────────────────────────────────────────────────────────
  Future<bool> deleteTask(String id) async {
    try {
      await ApiService.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
