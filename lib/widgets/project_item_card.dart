import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class ProjectItemCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ProjectItemCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  String _formatElapsedTime(int seconds) {
    if (seconds < 60) {
      return '0m';
    }
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final Color projectColor = project.color != null 
        ? Color(int.parse(project.color!.replaceAll('#', '0xFF')))
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: projectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              StreamBuilder<List<Task>>(
                stream: _firestoreService.getTasks(project.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Row(
                      children: [
                        Text(
                          '0m',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '0',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                  
                  final tasks = snapshot.data!;
                  final totalSeconds = tasks.fold<int>(
                    0,
                    (sum, task) => sum + (task.elapsedTime ?? 0),
                  );
                  final incompleteTasks = tasks.where((task) => !task.completed).length;
                  
                  return Row(
                    children: [
                      Text(
                        _formatElapsedTime(totalSeconds),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$incompleteTasks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
              PopupMenuButton<String>(
                iconColor: Colors.white70,
                onSelected: (String result) {
                  if (result == 'edit') {
                    onEdit?.call();
                  } else if (result == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 