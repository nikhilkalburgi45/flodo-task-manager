// lib/models/task.dart
//
// This mirrors the Task schema from our Node.js backend exactly.
// fromJson() parses the API response, toJson() sends data to the API.

class BlockedByTask {
  final String id;
  final String title;
  final String status;

  BlockedByTask({required this.id, required this.title, required this.status});

  factory BlockedByTask.fromJson(Map<String, dynamic> json) {
    return BlockedByTask(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final BlockedByTask? blockedBy; // null if not blocked
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
    required this.createdAt,
  });

  // Is this task currently blocked?
  // A task is blocked only if blockedBy exists AND the blocking task is NOT "Done"
  bool get isBlocked =>
      blockedBy != null && blockedBy!.status != 'Done';

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'] ?? 'To-Do',
      blockedBy: json['blockedBy'] != null && json['blockedBy'] is Map
          ? BlockedByTask.fromJson(json['blockedBy'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'blockedBy': blockedBy?.id,
    };
  }

  // Creates a copy with some fields changed — useful for local state updates
  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    BlockedByTask? blockedBy,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: clearBlockedBy ? null : (blockedBy ?? this.blockedBy),
      createdAt: createdAt,
    );
  }
}

// Valid status values — matches the backend enum
const List<String> taskStatuses = ['To-Do', 'In Progress', 'Done'];
