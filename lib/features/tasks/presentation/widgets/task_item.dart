import 'package:flutter/material.dart';
import '../../../../models/task.dart';
import '../pages/pomodoro_timer_page.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../pomodoro/domain/repositories/pomodoro_repository.dart';
import '../../../projects/data/models/task_model.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPlayPomodoro;
  final String projectId;
  final String projectName;

  const TaskItem({
    Key? key,
    required this.task,
    required this.projectId,
    required this.projectName,
    this.onToggleCompleted,
    this.onDelete,
    this.onEdit,
    this.onPlayPomodoro,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: TaskItem build user: \\${user?.uid}');
    if (user == null) return const SizedBox.shrink();

    print('DEBUG: Fetching pomodoroSessions for user: \\${user.uid}, taskId: \\${task.id}');
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pomodoroSessions')
          .where('taskId', isEqualTo: task.id)
          .where('isCompleted', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        int completedCount = 0;
        if (snapshot.hasData) {
          completedCount = snapshot.data!.docs.length;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: Colors.grey.shade900, // Dark background color
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PomodoroTimerPage(
                    projectId: projectId,
                    projectName: projectName,
                    task: task,
                    autostart: false,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggleCompleted,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: task.completed ? Colors.green : Colors.grey, width: 2),
                        color: task.completed ? Colors.green : Colors.transparent,
                      ),
                      child: task.completed
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Task Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: task.completed ? TextDecoration.lineThrough : TextDecoration.none,
                            color: task.completed ? Colors.grey : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Display completion date for completed tasks or deadline for pending tasks
                        if (task.completed && task.completedAt != null) ...[ 
                          const SizedBox(height: 4),
                          Row(
                            children: [
                               Icon(Icons.check_circle, size: 14, color: Colors.grey.shade600), // Completed icon
                               const SizedBox(width: 4),
                               Text(
                                  'Completed: ${DateFormat('MMM d, yyyy').format(task.completedAt!)}', // Format completed date
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                               ),
                            ],
                          ),
                        ] else if (!task.completed && task.dueDate != null) ...[ // For pending tasks with a deadline
                          const SizedBox(height: 4),
                          Row(
                            children: [
                               Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600), // Deadline icon
                               const SizedBox(width: 4),
                               Text(
                                  'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate!)}', // Format deadline date
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                               ),
                            ],
                          ),
                        ],
                        // Optionally keep completed pomodoros count here if still desired
                        if (completedCount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer, size: 16, color: Colors.orangeAccent),
                              const SizedBox(width: 2),
                              Text(
                                completedCount.toString(),
                                style: const TextStyle(fontSize: 14, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Play Button
                  GestureDetector(
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PomodoroTimerPage(
                            projectId: projectId,
                            projectName: projectName,
                            task: task,
                            autostart: true,
                          ),
                        ),
                      );
                    },
                    child: Container(
                       padding: const EdgeInsets.all(8.0), // Add some padding around the icon
                       child: Icon(
                        Icons.play_arrow,
                        color: Colors.grey.shade600, // Match the mockup's play button color
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String getMonthAbbreviation(int month) {
    const List<String> monthAbbreviations = [
      '', // Month is 1-indexed
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return monthAbbreviations[month];
  }
} 