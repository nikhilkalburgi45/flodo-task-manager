// lib/screens/task_form_screen.dart
//
// Handles both CREATE and EDIT.
// If `task` param is passed → Edit mode. Otherwise → Create mode.
//
// DRAFTS: When the user types in the title/description and then swipes back
// or minimizes the app, the text is saved to SharedPreferences automatically.
// When they open the Create screen again, the draft is restored.
// Drafts are only saved for CREATE mode (not edit, since edit has existing data).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = create mode, non-null = edit mode

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedStatus = 'To-Do';
  String? _selectedBlockedById; // ID of the blocking task

  bool get _isEditMode => widget.task != null;

  // Draft keys for SharedPreferences
  static const String _draftTitleKey = 'draft_title';
  static const String _draftDescKey = 'draft_desc';

  @override
  void initState() {
    super.initState();

    if (_isEditMode) {
      // Pre-fill form with existing task data
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedStatus = widget.task!.status;
      _selectedBlockedById = widget.task!.blockedBy?.id;
    } else {
      // Restore draft if it exists
      _loadDraft();
    }

    // Auto-save draft on every keystroke (create mode only)
    if (!_isEditMode) {
      _titleController.addListener(_saveDraft);
      _descController.addListener(_saveDraft);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Draft: Save to SharedPreferences ─────────────────────────────────────
  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTitleKey, _titleController.text);
    await prefs.setString(_draftDescKey, _descController.text);
  }

  // ── Draft: Load from SharedPreferences ───────────────────────────────────
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTitle = prefs.getString(_draftTitleKey) ?? '';
    final savedDesc = prefs.getString(_draftDescKey) ?? '';

    if (savedTitle.isNotEmpty || savedDesc.isNotEmpty) {
      setState(() {
        _titleController.text = savedTitle;
        _descController.text = savedDesc;
      });
    }
  }

  // ── Draft: Clear after successful save ────────────────────────────────────
  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTitleKey);
    await prefs.remove(_draftDescKey);
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Submit form ───────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'dueDate': _selectedDate!.toIso8601String(),
      'status': _selectedStatus,
      if (_selectedBlockedById != null) 'blockedBy': _selectedBlockedById,
    };

    final provider = context.read<TaskProvider>();
    bool success;

    if (_isEditMode) {
      success = await provider.updateTask(widget.task!.id, data);
    } else {
      success = await provider.createTask(data);
    }

    if (!mounted) return;

    if (success) {
      if (!_isEditMode) await _clearDraft();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Task updated successfully!'
              : 'Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // ── Form ────────────────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildLabel('Title *'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Enter task title'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildLabel('Description'),
                      TextFormField(
                        controller: _descController,
                        decoration: _inputDecoration('Enter description (optional)'),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: 16),

                      // Due Date
                      _buildLabel('Due Date *'),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 18, color: Colors.grey.shade500),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDate != null
                                    ? DateFormat('dd MMM yyyy')
                                        .format(_selectedDate!)
                                    : 'Select due date',
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Status
                      _buildLabel('Status'),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            items: taskStatuses
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStatus = value);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Blocked By
                      _buildLabel('Blocked By (optional)'),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedBlockedById,
                            hint: const Text('None'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None'),
                              ),
                              // Show all tasks EXCEPT the current one
                              ...provider.tasks
                                  .where((t) => t.id != widget.task?.id)
                                  .map((t) => DropdownMenuItem<String?>(
                                        value: t.id,
                                        child: Text(
                                          t.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedBlockedById = value);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          // Disabled while saving — prevents double-tap
                          onPressed: provider.isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: provider.isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditMode ? 'Update Task' : 'Create Task',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Loading overlay during 2s backend delay ──────────────────
              if (provider.isSaving)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Saving task...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Helper: section label ──────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ── Helper: consistent input decoration ───────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }
}
