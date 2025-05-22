import 'package:flutter/material.dart';
import '../../../../models/task.dart';

class PomodoroTimerPage extends StatelessWidget {
  final String projectId;
  final String projectName;
  final Task task;

  const PomodoroTimerPage({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(task.title), // Display the task title
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Back button
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Pomodoro Timer UI
            Text(
              'Project: $projectName',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const Text(
              '25:00', // Placeholder timer display
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Focus time', // Placeholder label
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay, size: 36),
                  onPressed: () {
                    // TODO: Implement replay logic
                  },
                ),
                const SizedBox(width: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrangeAccent, // Match mockup play button color
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement play/pause logic
                       print('Play button tapped for task: ${task.title}');
                    },
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36),
                  onPressed: () {
                    // TODO: Implement skip logic
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 