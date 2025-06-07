import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/task.dart';
import '../../../../services/firestore_service.dart';
import '../widgets/task_item.dart';
import './pomodoro_timer_page.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:intl/intl.dart';
import '../../../../screens/home_page.dart';

/// A page that displays the list of tasks for a specific project.
/// Features include:
/// - Viewing tasks with their completion status
/// - Adding new tasks
/// - Editing existing tasks
/// - Starting Pomodoro sessions for tasks
/// - Tracking task statistics
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
  int _totalElapsedTime = 0; // Total elapsed time across all tasks
  StreamSubscription<List<Task>>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    // Subscribe to task updates from Firestore
    _tasksSubscription = _firestoreService.getTasks(widget.projectId).listen((tasks) {
      setState(() {
        _allTasks = tasks;
        _tasksToBeCompletedCount = _allTasks.where((task) => !task.completed).length;
        _completedTasksCount = _allTasks.where((task) => task.completed).length;
        _totalElapsedTime = _allTasks.fold(0, (sum, task) => sum + task.elapsedTime);
      });
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  /// Shows the dialog for adding a new task
  Future<void> _showAddTaskDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController estimatedPomodorosController = TextEditingController();
    DateTime? selectedDeadline;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Add New Task', style: TextStyle(color: Colors.black)),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none, // Remove default border
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjust padding
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: estimatedPomodorosController,
                  decoration: InputDecoration(
                    labelText: 'Estimated Pomodoros',
                     labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Adjust padding
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                // Deadline Selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDeadline == null
                                  ? 'No deadline set'
                                  : DateFormat('MMM d, yyyy').format(selectedDeadline!),
                              style: TextStyle(
                                color: selectedDeadline == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeadline ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.blueAccent, // Header background
                                        onPrimary: Colors.white, // Header text
                                        onSurface: Colors.black87, // Calendar text
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                      // You can add more customizations here
                                      textTheme: const TextTheme(
                                        bodyMedium: TextStyle(color: Colors.black87), // Calendar day text
                                      ),
                                      buttonTheme: const ButtonThemeData(
                                        textTheme: ButtonTextTheme.primary, // Dialog button text color
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                selectedDeadline = pickedDate;
                                (context as Element).markNeedsBuild();
                              }
                            },
                            icon: Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                            label: const Text('Select Date', style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final task = Task(
                  id: '',
                  projectId: widget.projectId,
                  title: titleController.text,
                  estimatedPomodoros: int.tryParse(estimatedPomodorosController.text) ?? 0,
                  createdAt: DateTime.now(),
                  dueDate: selectedDeadline,
                );
                await _firestoreService.addTask(widget.projectId, task);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Task', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Stats Card
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            color: Colors.grey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('HH    MM', '00:00', 'Estimated Time'),
                  _buildStatColumn('', _tasksToBeCompletedCount.toString(), 'Tasks to be Completed'),
                  _buildStatColumn('HH    MM', _formatDuration(_totalElapsedTime), 'Elapsed Time'),
                  _buildStatColumn('', _completedTasksCount.toString(), 'Completed Tasks'),
                ],
              ),
            ),
          ),
          // Add Task Button
          GestureDetector(
            onTap: _showAddTaskDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
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
            child: Column(
              children: [
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
                      _allTasks = snapshot.data ?? [];

                      // Filter and sort tasks
                      final List<Task> filteredTasks;
                      if (_showCompletedTasks) {
                        // Show incomplete tasks first, then completed tasks sorted by completion date (latest first)
                        final incompleteTasks = _allTasks.where((task) => !task.completed).toList();
                        final completedTasks = _allTasks.where((task) => task.completed).toList();
                        completedTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!)); // Sort by completedAt descending
                        filteredTasks = [...incompleteTasks, ...completedTasks];
                      } else {
                        // Show only incomplete tasks
                        filteredTasks = _allTasks.where((task) => !task.completed).toList();
                      }

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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return TaskItem(
                            task: task,
                            projectId: widget.projectId,
                            projectName: widget.projectName,
                            onToggleCompleted: () {
                              _firestoreService.updateTask(
                                widget.projectId,
                                task.copyWith(
                                  completed: !task.completed,
                                  completedAt: task.completed ? null : DateTime.now(),
                                ),
                              );
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
                                    autostart: true,
                                  ),
                                ),
                              );
                            },
                            onEdit: () {
                              // TODO: Show Edit Task Dialog and pass task data
                              print('Edit task: ${task.title}');
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // Show/Hide Completed Tasks button
                if (_allTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                const SizedBox(height: 16),
                // Centered Home Button
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FloatingActionButton(
                      elevation: 4,
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        // Navigate to home page
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                          (route) => false, // Remove all previous routes
                        );
                      },
                      child: const Icon(Icons.home, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  /// Builds a column for displaying statistics
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