import 'package:flutter/material.dart';
import '../../../../models/task.dart';
import '../pages/pomodoro_timer_page.dart';

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
    // Placeholder for project color - tasks don't have color directly
    // You might pass project color from ProjectDetailScreen if needed for styling
    // final Color projectColor = Colors.blue; 

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: Colors.grey.shade900, // Dark background color
      child: InkWell(
        onTap: onEdit, // Assuming tapping the task item opens edit/details
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                    if (task.completedPomodoros > 0 || task.dueDate != null) ...[ // Display completedPomodoros
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.completedPomodoros > 0) ...[ // Display completedPomodoros
                            Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${task.completedPomodoros}', // Display completedPomodoros
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (task.dueDate != null) const SizedBox(width: 16),
                          ],
                          if (task.dueDate != null) ...[
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              // Format date as 'Sun, 15 Jan 2023'
                              task.dueDate != null
                                  ? '${task.dueDate!.day} ${getMonthAbbreviation(task.dueDate!.month)} ${task.dueDate!.year}'
                                  : '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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