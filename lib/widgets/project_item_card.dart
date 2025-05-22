import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectItemCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  // Removed onEdit as per desired UI simplification

  const ProjectItemCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder color. Add color to Project model for dynamic color.
    final Color projectColor = Colors.blue;

    // Placeholder for time spent (0m).
    const String timeSpent = '0m';

    // Placeholder for active tasks count.
    // Fetch this count from the tasks subcollection later.
    const int activeTasks = 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0), // Adjusted margin for list appearance
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Slightly less rounded
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjusted padding
          child: Row(
            children: [
              // Colored Circle
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: projectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Project Name
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              // Time Spent (Placeholder)
              Text(
                timeSpent,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              // Task Count (Placeholder)
              Text(
                '$activeTasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Removed PopupMenuButton for simplicity as per image
            ],
          ),
        ),
      ),
    );
  }
} 