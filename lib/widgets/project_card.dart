import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final VoidCallback onAddProject;

  const ProjectCard({
    super.key,
    required this.onAddProject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Your First Project',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start organizing your tasks by creating a project. You can add tasks, track time, and monitor your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            FloatingActionButton.extended(
              onPressed: onAddProject,
              backgroundColor: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.add),
              label: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }
} 