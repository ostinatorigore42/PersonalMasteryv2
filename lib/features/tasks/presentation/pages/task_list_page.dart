import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/task.dart';
import '../../../../services/firestore_service.dart';
import '../widgets/task_item.dart';
import '../../../pomodoro/presentation/pages/pomodoro_timer_page.dart';
import 'dart:async'; // Import for StreamSubscription

class TaskListPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const TaskListPage({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Task> _allTasks = [];
  bool _showCompletedTasks = false;
  int _tasksToBeCompletedCount = 0;
  int _completedTasksCount = 0;
  int _totalElapsedTime = 0; // Add total elapsed time state variable
  StreamSubscription<List<Task>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _tasksSubscription = _firestoreService.getTasks(widget.projectId).listen((tasks) {
      setState(() {
        _allTasks = tasks;
        _tasksToBeCompletedCount = _allTasks.where((task) => !task.completed).length;
        _completedTasksCount = _allTasks.where((task) => task.completed).length;
        _totalElapsedTime = _allTasks.fold(0, (sum, task) => sum + task.elapsedTime); // Calculate total elapsed time
      });
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showAddTaskDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController estimatedPomodorosController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: estimatedPomodorosController,
              decoration: const InputDecoration(labelText: 'Estimated Pomodoros'),
              keyboardType: TextInputType.number,
            ),
            // Add Due Date Picker later
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final task = Task(
                  id: '', // Firestore will generate the ID
                  projectId: widget.projectId,
                  title: titleController.text,
                  estimatedPomodoros: int.tryParse(estimatedPomodorosController.text) ?? 0,
                  createdAt: DateTime.now(),
                );
                await _firestoreService.addTask(widget.projectId, task);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate counts here, inside the build method, so they update with snapshot data
    // final tasksToBeCompletedCount = _allTasks.where((task) => !task.completed).length;
    // final completedTasksCount = _allTasks.where((task) => task.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            icon: Icon(_showCompletedTasks ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                _showCompletedTasks = !_showCompletedTasks;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card (Placeholder) - Updated Styling
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0), // Match mockup
            ),
            color: Colors.grey.shade900, // Match mockup background
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('HH    MM', '00:00', 'Estimated Time'),
                  _buildStatColumn('', _tasksToBeCompletedCount.toString(), 'Tasks to be Completed'),
                  _buildStatColumn('HH    MM', _formatDuration(_totalElapsedTime), 'Elapsed Time'), // Display total elapsed time
                  _buildStatColumn('', _completedTasksCount.toString(), 'Completed Tasks'),
                ],
              ),
            ),
          ),
          // Add Task Button - Updated Styling
          GestureDetector(
            onTap: _showAddTaskDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900, // Match mockup background
                borderRadius: BorderRadius.circular(16.0), // Match mockup
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0), // Adjust padding as needed
                      child: Icon(Icons.add, color: Colors.black, size: 24.0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Add a task...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
          // Tasks List
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _firestoreService.getTasks(widget.projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                _allTasks = snapshot.data ?? []; // Store all fetched tasks

                // Filter and sort tasks
                final List<Task> filteredTasks;
                if (_showCompletedTasks) {
                  // Show incomplete tasks first, then completed tasks
                  final incompleteTasks = _allTasks.where((task) => !task.completed).toList();
                  final completedTasks = _allTasks.where((task) => task.completed).toList();
                  filteredTasks = [...incompleteTasks, ...completedTasks];
                } else {
                  // Show only incomplete tasks
                  filteredTasks = _allTasks.where((task) => !task.completed).toList();
                }

                // Recalculate counts here after _allTasks is updated
                // final tasksToBeCompletedCount = _allTasks.where((task) => !task.completed).length;
                // final completedTasksCount = _allTasks.where((task) => task.completed).length;

                if (filteredTasks.isEmpty) {
                   if (_allTasks.isNotEmpty && _showCompletedTasks) {
                     return const Center(child: Text('No completed tasks yet.'));
                   } else if (_allTasks.isNotEmpty && !_showCompletedTasks) {
                     return const Center(child: Text('All tasks are completed!'));
                   } else {
                     return const Center(child: Text('No tasks yet. Add one!'));
                   }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return TaskItem(
                      task: task,
                      projectId: widget.projectId,
                      projectName: widget.projectName,
                      onToggleCompleted: () {
                        _firestoreService.updateTask(widget.projectId, task.copyWith(completed: !task.completed, completedAt: task.completed ? null : DateTime.now()));
                      },
                      onDelete: () {
                        _firestoreService.deleteTask(widget.projectId, task.id);
                      },
                      onPlayPomodoro: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PomodoroTimerPage(
                              projectId: widget.projectId,
                              projectName: widget.projectName,
                              task: task,
                            ),
                          ),
                        );
                      },
                      onEdit: () {
                        // TODO: Show Edit Task Dialog and pass task data
                        print('Edit task: ${task.title}');
                      }
                    );
                  },
                );
              },
            ),
          ),
           // Show/Hide Completed Tasks button
          if (_allTasks.isNotEmpty) // Only show if there are any tasks
             Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                 onTap: () {
                   setState(() {
                     _showCompletedTasks = !_showCompletedTasks;
                   });
                 },
                 child: Text(
                   _showCompletedTasks ? 'Hide Completed Tasks' : 'Show Completed Tasks',
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.grey.shade600, fontSize: 16.0),
                 ),
              ),
            ),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper to format seconds into HH:MM:SS
  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStatColumn(String hhMm, String value, String label) {
    return Column(
      children: [
        Text(
          hhMm,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
} 