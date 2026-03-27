// lib/widgets/task_card.dart
//
// Displays a single task in the list.
// If the task is blocked (blockedBy task is not "Done"), the card is greyed out
// and shows a "Blocked" banner — as required by the assignment.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  // Returns a color for each status badge
  Color _statusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool blocked = task.isBlocked;

    return Opacity(
      // Greyed out if blocked — assignment requirement
      opacity: blocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: blocked ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: blocked
              ? const BorderSide(color: Colors.grey, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: title + delete button ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == 'Done'
                              ? TextDecoration.lineThrough
                              : null,
                          color: blocked ? Colors.grey : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade300,
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                // ── Description (if any) ─────────────────────────────────────
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ── Bottom row: status badge + due date + blocked banner ──────
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(task.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _statusColor(task.status), width: 1),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(task.status),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Due date
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(task.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const Spacer(),

                    // Blocked banner — only shown when task is actively blocked
                    if (blocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.red.shade300, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                size: 11, color: Colors.red.shade400),
                            const SizedBox(width: 3),
                            Text(
                              'Blocked',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // ── Blocked by info ──────────────────────────────────────────
                if (blocked) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Waiting for: "${task.blockedBy!.title}"',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
