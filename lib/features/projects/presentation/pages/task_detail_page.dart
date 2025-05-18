import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/project_bloc.dart';
import '../../../pomodoro/presentation/bloc/pomodoro_bloc.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({Key? key}) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  @override
  Widget build(BuildContext context) {
    // Extract task ID from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final taskId = args?['taskId'] as String?;

    if (taskId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
        ),
        body: const Center(
          child: Text('Task not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            if (state is TaskDetailsLoaded) {
              return Text(state.task['title'] as String);
            }
            return const Text('Task Details');
          },
        ),
        actions: [
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              if (state is TaskDetailsLoaded) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _editTask(context, taskId, state.task);
                    } else if (value == 'complete') {
                      context.read<ProjectBloc>().add(
                            UpdateTaskEvent(
                              taskId,
                              {'isCompleted': true},
                            ),
                          );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text(
                            'Are you sure you want to delete this task? '
                            'This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        context.read<ProjectBloc>().add(DeleteTaskEvent(taskId));
                        Navigator.of(context).pop(); // Return to previous screen
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final isCompleted = state.task['isCompleted'] as bool? ?? false;
                    
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Task'),
                          ],
                        ),
                      ),
                      if (!isCompleted)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle),
                              SizedBox(width: 8),
                              Text('Mark as Completed'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Task', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is TaskActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            
            // Go back to previous screen if task was deleted
            if (state.message.contains('deleted')) {
              Navigator.of(context).pop();
            } else {
              // Refresh task details
              context.read<ProjectBloc>().add(LoadTaskDetailsEvent(taskId));
            }
          } else if (state is ProjectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProjectsLoading) {
            return const LoadingIndicator();
          } else if (state is TaskDetailsLoaded) {
            final task = state.task;
            final project = state.project;
            
            // Check if task is completed
            final isCompleted = task['isCompleted'] as bool? ?? false;
            
            // Get project color if available
            Color projectColor = Colors.blue;
            if (project != null && project['color'] != null) {
              final colorHex = project['color'] as String;
              projectColor = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
            }
            
            // Get priority color
            final priority = task['priority'] as String? ?? 'medium';
            Color priorityColor;
            if (priority == 'high') {
              priorityColor = Colors.red;
            } else if (priority == 'medium') {
              priorityColor = Colors.orange;
            } else {
              priorityColor = Colors.green;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8.0),
                          Text(
                            'This task is completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isCompleted) const SizedBox(height: 16.0),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (project != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: projectColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: projectColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        project['name'] as String,
                                        style: TextStyle(
                                          color: projectColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            task['title'] as String,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                          if (task['description'] != null && (task['description'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              task['description'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          if (task['dueDate'] != null) ...[
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Due Date'),
                              subtitle: Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(
                                  DateTime.parse(task['dueDate'] as String),
                                ),
                              ),
                              dense: true,
                            ),
                            const Divider(),
                          ],
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('Created'),
                            subtitle: Text(
                              DateFormat('MMMM d, yyyy - h:mm a').format(
                                DateTime.parse(task['createdAt'] as String),
                              ),
                            ),
                            dense: true,
                          ),
                          if (task['estimatedPomodoros'] != null) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.timer),
                              title: const Text('Estimated Pomodoros'),
                              subtitle: Text(
                                '${task['estimatedPomodoros']} sessions (${task['estimatedPomodoros'] * 25} minutes)',
                              ),
                              dense: true,
                            ),
                          ],
                          if (task['completedPomodoros'] != null) ...[
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.timelapse),
                              title: const Text('Completed Pomodoros'),
                              subtitle: Text(
                                '${task['completedPomodoros']} sessions (${task['completedPomodoros'] * 25} minutes)',
                              ),
                              dense: true,
                            ),
                          ],
                          if (task['goalId'] != null) ...[
                            const Divider(),
                            FutureBuilder<Map<String, dynamic>?>(
                              future: context.read<GoalBloc>().goalRepository.getGoal(task['goalId'] as String),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final goal = snapshot.data!;
                                  return ListTile(
                                    leading: const Icon(Icons.flag),
                                    title: const Text('Associated Goal'),
                                    subtitle: Text(goal['title'] as String),
                                    dense: true,
                                    onTap: () {
                                      context.read<GoalBloc>().add(LoadGoalDetailsEvent(goal['id'] as String));
                                      Navigator.of(context).pushNamed(RouteConstants.goals);
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                          if (task['tags'] != null && (task['tags'] as List).isNotEmpty) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: (task['tags'] as List).map((tag) {
                                  return Chip(
                                    label: Text(tag as String),
                                    backgroundColor: Colors.grey[200],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pomodoro Sessions Section
                  if (task['pomodoroSessionIds'] != null && (task['pomodoroSessionIds'] as List).isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pomodoro Sessions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _loadPomodoroSessions(task['pomodoroSessionIds'] as List<dynamic>),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Text('No pomodoro sessions found');
                                }
                                
                                final sessions = snapshot.data!;
                                sessions.sort((a, b) {
                                  final aDate = DateTime.parse(a['endTime'] as String);
                                  final bDate = DateTime.parse(b['endTime'] as String);
                                  return bDate.compareTo(aDate); // Sort by end time (newest first)
                                });
                                
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sessions.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final session = sessions[index];
                                    final startTime = DateTime.parse(session['startTime'] as String);
                                    final endTime = DateTime.parse(session['endTime'] as String);
                                    final duration = endTime.difference(startTime);
                                    final rating = session['rating'] as double?;
                                    
                                    return ListTile(
                                      leading: const Icon(Icons.timer),
                                      title: Text(
                                        '${duration.inMinutes} minutes session',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(DateFormat('MMM d, yyyy - h:mm a').format(startTime)),
                                          if (rating != null)
                                            Row(
                                              children: [
                                                const Text('Rating: '),
                                                for (int i = 0; i < 5; i++)
                                                  Icon(
                                                    i < rating ? Icons.star : Icons.star_border,
                                                    size: 16,
                                                    color: i < rating ? Colors.amber : Colors.grey,
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      isThreeLine: rating != null,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (!isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Start Pomodoro',
                            icon: Icons.timer,
                            onPressed: () {
                              // Start a pomodoro session for this task
                              final pomodoroBloc = context.read<PomodoroBloc>();
                              pomodoroBloc.add(StartNewSessionEvent(
                                taskId: taskId,
                                taskTitle: task['title'] as String,
                                projectName: project?['name'] as String?,
                              ));
                              Navigator.of(context).pushNamed(RouteConstants.pomodoro);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Mark as Completed',
                            icon: Icons.check_circle,
                            onPressed: () {
                              context.read<ProjectBloc>().add(
                                    UpdateTaskEvent(
                                      taskId,
                                      {'isCompleted': true},
                                    ),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          } else {
            // Initial load, trigger loading of task details
            context.read<ProjectBloc>().add(LoadTaskDetailsEvent(taskId));
            return const LoadingIndicator();
          }
        },
      ),
    );
  }

  void _editTask(BuildContext context, String taskId, Map<String, dynamic> taskData) {
    showDialog(
      context: context,
      builder: (context) => _EditTaskDialog(
        taskId: taskId,
        initialData: taskData,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadPomodoroSessions(List<dynamic> sessionIds) async {
    final pomodoroRepo = context.read<PomodoroBloc>().pomodoroRepository;
    final List<Map<String, dynamic>> sessions = [];
    
    for (final sessionId in sessionIds) {
      final session = await pomodoroRepo.getPomodoroSession(sessionId as String);
      if (session != null) {
        sessions.add(session);
      }
    }
    
    return sessions;
  }
}

class _EditTaskDialog extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> initialData;

  const _EditTaskDialog({
    required this.taskId,
    required this.initialData,
  });

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  DateTime? _dueDate;
  late int? _estimatedPomodoros;
  List<String> _selectedTags = [];
  String? _goalId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title'] as String);
    _descriptionController = TextEditingController(text: widget.initialData['description'] as String? ?? '');
    _priority = widget.initialData['priority'] as String? ?? 'medium';
    
    if (widget.initialData['dueDate'] != null) {
      _dueDate = DateTime.parse(widget.initialData['dueDate'] as String);
    }
    
    _estimatedPomodoros = widget.initialData['estimatedPomodoros'] as int?;
    
    if (widget.initialData['tags'] != null) {
      _selectedTags = List<String>.from(widget.initialData['tags'] as List<dynamic>);
    }
    
    _goalId = widget.initialData['goalId'] as String?;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _updateTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _priority,
        'dueDate': _dueDate?.toIso8601String(),
        'estimatedPomodoros': _estimatedPomodoros,
        'tags': _selectedTags,
        'goalId': _goalId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      context.read<ProjectBloc>().add(UpdateTaskEvent(widget.taskId, updates));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'low',
                    label: Text('Low'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<String>(
                    value: 'medium',
                    label: Text('Medium'),
                    icon: Icon(Icons.remove),
                  ),
                  ButtonSegment<String>(
                    value: 'high',
                    label: Text('High'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _priority = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date (Optional)'),
                subtitle: _dueDate != null
                    ? Text(DateFormat('EEEE, MMMM d, yyyy').format(_dueDate!))
                    : const Text('No due date selected'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDueDate,
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                      ),
                  ],
                ),
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Estimated Pomodoros (Optional)'),
                subtitle: const Text('How many 25-minute sessions?'),
                trailing: DropdownButton<int?>(
                  value: _estimatedPomodoros,
                  hint: const Text('Select'),
                  items: [null, 1, 2, 3, 4, 5, 6, 7, 8]
                      .map((e) => DropdownMenuItem<int?>(
                            value: e,
                            child: Text(e?.toString() ?? 'None'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _estimatedPomodoros = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tags (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<String>>(
                future: context.read<ProjectBloc>().projectRepository.getAvailableTags(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  
                  final availableTags = snapshot.data!;
                  return Wrap(
                    spacing: 8.0,
                    children: availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Associated Goal (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: context.read<GoalBloc>().goalRepository.getActiveGoals(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  
                  final goals = snapshot.data!;
                  return DropdownButtonFormField<String?>(
                    value: _goalId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    hint: const Text('Select a goal (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...goals.map((goal) => DropdownMenuItem<String?>(
                            value: goal['id'] as String,
                            child: Text(goal['title'] as String),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _goalId = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateTask,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
