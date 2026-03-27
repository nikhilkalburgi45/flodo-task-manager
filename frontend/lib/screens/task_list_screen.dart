// lib/screens/task_list_screen.dart
//
// The main screen. Shows all tasks with:
//   - Search bar (text input)
//   - Status filter (dropdown)
//   - FAB to create new task
//   - Pull-to-refresh

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filter options — "All" means no filter
  final List<String> _statusOptions = [
    'All',
    'To-Do',
    'In Progress',
    'Done',
  ];

  @override
  void initState() {
    super.initState();
    // Load tasks when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Show delete confirmation dialog
  void _confirmDelete(BuildContext context, String taskId, String taskTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await context.read<TaskProvider>().deleteTask(taskId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.read<TaskProvider>().error ?? 'Delete failed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<TaskProvider>().setSearch('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to show/hide clear button
                      context.read<TaskProvider>().setSearch(value);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // Status filter dropdown
                Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.statusFilter,
                          items: _statusOptions
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              provider.setStatusFilter(value);
                            }
                          },
                          icon: const Icon(Icons.filter_list, size: 16),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Task list ──────────────────────────────────────────────────────
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                // Loading state
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(provider.error!,
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.loadTasks(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          provider.searchQuery.isNotEmpty
                              ? 'No tasks match your search'
                              : 'No tasks yet. Tap + to create one!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // Task list
                return RefreshIndicator(
                  onRefresh: () => provider.loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () {
                          // Navigate to edit screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskFormScreen(task: task),
                            ),
                          ).then((_) => provider.loadTasks());
                        },
                        onDelete: () =>
                            _confirmDelete(context, task.id, task.title),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB: Create new task ───────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          ).then((_) => context.read<TaskProvider>().loadTasks());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
