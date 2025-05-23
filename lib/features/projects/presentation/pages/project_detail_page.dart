import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/project_bloc.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({Key? key}) : super(key: key);

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    // Extract project ID from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final projectId = args?['projectId'] as String?;

    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Project Details'),
        ),
        body: const Center(
          child: Text('Project not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            if (state is ProjectDetailsLoaded) {
              return Text(state.project['name'] as String);
            }
            return const Text('Project Details');
          },
        ),
        actions: [
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              if (state is ProjectDetailsLoaded) {
                return IconButton(
                  icon: Icon(_showCompleted ? Icons.check_circle : Icons.check_circle_outline),
                  tooltip: _showCompleted ? 'Hide completed tasks' : 'Show completed tasks',
                  onPressed: () {
                    setState(() {
                      _showCompleted = !_showCompleted;
                    });
                    context.read<ProjectBloc>().add(
                          LoadTasksEvent(
                            projectId: projectId,
                            includeCompleted: _showCompleted,
                          ),
                        );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              if (state is ProjectDetailsLoaded) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      showDialog(
                        context: context,
                        builder: (context) => _EditProjectDialog(
                          projectId: projectId,
                          initialData: state.project,
                        ),
                      );
                    } else if (value == 'archive') {
                      context.read<ProjectBloc>().add(ArchiveProjectEvent(projectId));
                    } else if (value == 'unarchive') {
                      context.read<ProjectBloc>().add(
                            UpdateProjectEvent(
                              projectId,
                              {'isArchived': false},
                            ),
                          );
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Project'),
                          content: const Text(
                            'Are you sure you want to delete this project? '
                            'This will also delete all tasks in this project. '
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
                        context.read<ProjectBloc>().add(DeleteProjectEvent(projectId));
                        Navigator.of(context).pop(); // Return to projects list
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final isArchived = state.project['isArchived'] as bool? ?? false;
                    
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit Project'),
                          ],
                        ),
                      ),
                      if (!isArchived)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive),
                              SizedBox(width: 8),
                              Text('Archive Project'),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'unarchive',
                          child: Row(
                            children: [
                              Icon(Icons.unarchive),
                              SizedBox(width: 8),
                              Text('Unarchive Project'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Project', style: TextStyle(color: Colors.red)),
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
          if (state is ProjectActionSuccess || state is TaskActionSuccess) {
            final message = state is ProjectActionSuccess
                ? state.message
                : (state as TaskActionSuccess).message;
                
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
            
            // Refresh tasks after a task action
            if (state is TaskActionSuccess) {
              context.read<ProjectBloc>().add(
                    LoadTasksEvent(
                      projectId: projectId,
                      includeCompleted: _showCompleted,
                    ),
                  );
            }
            
            // Go back to projects list if the project was deleted
            if (state is ProjectActionSuccess && state.message.contains('deleted')) {
              Navigator.of(context).pop();
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
          } else if (state is ProjectDetailsLoaded) {
            final project = state.project;
            final tasks = state.tasks;
            final isArchived = project['isArchived'] as bool? ?? false;
            
            // Get the project color
            final colorHex = project['color'] as String? ?? '#2196F3';
            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

            return Column(
              children: [
                if (isArchived)
                  Container(
                    color: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text(
                        'This project is archived',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (project['description'] != null && project['description'] != '')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: color.withOpacity(0.1),
                    child: Text(
                      project['description'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ),
                Expanded(
                  child: tasks.isEmpty
                      ? _buildEmptyTasksState(projectId, isArchived)
                      : _buildTasksList(tasks, projectId, isArchived, color),
                ),
              ],
            );
          } else {
            // Initial load, trigger loading of project details
            context.read<ProjectBloc>().add(LoadProjectDetailsEvent(projectId));
            return const LoadingIndicator();
          }
        },
      ),
      floatingActionButton: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (state is ProjectDetailsLoaded) {
            final isArchived = state.project['isArchived'] as bool? ?? false;
            
            if (!isArchived) {
              return FloatingActionButton.extended(
                onPressed: () => _createTask(context, projectId),
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyTasksState(String projectId, bool isArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.task_alt,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first task to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (!isArchived)
            CustomButton(
              text: 'Create Task',
              onPressed: () => _createTask(context, projectId),
              icon: Icons.add,
            ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks, String projectId, bool isArchived, Color projectColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final taskId = task['id'] as String;
        final title = task['title'] as String;
        final isCompleted = task['isCompleted'] as bool? ?? false;
        final priority = task['priority'] as String? ?? 'medium';
        final dueDate = task['dueDate'] as String?;
        
        Color priorityColor;
        if (priority == 'high') {
          priorityColor = Colors.red;
        } else if (priority == 'medium') {
          priorityColor = Colors.orange;
        } else {
          priorityColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              print('Task row tapped: navigating to Pomodoro');
              Navigator.of(context).pushNamed(
                RouteConstants.pomodoro,
                arguments: {
                  'taskId': taskId,
                  'projectName': project['name'] as String?,
                  'autostart': false,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    activeColor: projectColor,
                    onChanged: isArchived
                        ? null
                        : (value) {
                            if (value != null) {
                              context.read<ProjectBloc>().add(
                                    UpdateTaskEvent(
                                      taskId,
                                      {'isCompleted': value},
                                    ),
                                  );
                            } else {
                               context.read<ProjectBloc>().add(
                                    UpdateTaskEvent(
                                      taskId,
                                      {'isCompleted': false},
                                    ),
                                  );
                            }
                          },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : null,
                            fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        if (dueDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: _isDeadlineSoon(dueDate) && !isCompleted
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, yyyy').format(DateTime.parse(dueDate)),
                                style: TextStyle(
                                  color: _isDeadlineSoon(dueDate) && !isCompleted
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isArchived && !isCompleted)
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill),
                          color: projectColor,
                          tooltip: 'Start Pomodoro',
                          onPressed: () {
                            print('Play button tapped: navigating to Pomodoro with autostart');
                            Navigator.of(context).pushNamed(
                              RouteConstants.pomodoro,
                              arguments: {
                                'taskId': taskId,
                                'projectName': project['name'] as String?,
                                'autostart': true,
                              },
                            );
                          },
                        ),
                      if (!isArchived)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _editTask(context, taskId);
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
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _createTask(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(projectId: projectId),
    );
  }

  void _editTask(BuildContext context, String taskId) async {
    final taskData = await context.read<ProjectBloc>().projectRepository.getTask(taskId);
    if (taskData != null) {
      showDialog(
        context: context,
        builder: (context) => _EditTaskDialog(
          taskId: taskId,
          initialData: taskData,
        ),
      );
    }
  }

  bool _isDeadlineSoon(String deadlineStr) {
    final deadline = DateTime.parse(deadlineStr);
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }
}

class _EditProjectDialog extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> initialData;

  const _EditProjectDialog({
    required this.projectId,
    required this.initialData,
  });

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;

  // Predefined colors
  final List<String> _colors = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FFC107', // Amber
    '#F44336', // Red
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] as String);
    _descriptionController = TextEditingController(text: widget.initialData['description'] as String? ?? '');
    _selectedColor = widget.initialData['color'] as String? ?? '#2196F3';
    
    // If the color isn't in our predefined list, add it
    if (!_colors.contains(_selectedColor)) {
      _colors.add(_selectedColor);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateProject() {
    if (_formKey.currentState?.validate() ?? false) {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _selectedColor,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      context.read<ProjectBloc>().add(UpdateProjectEvent(widget.projectId, updates));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
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
                'Project Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((colorHex) {
                  final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                  final isSelected = _selectedColor == colorHex;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
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
          onPressed: _updateProject,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  final String projectId;

  const _CreateTaskDialog({
    required this.projectId,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  int? _estimatedPomodoros;

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

  void _createTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'projectId': widget.projectId,
        'priority': _priority,
        'dueDate': _dueDate?.toIso8601String(),
        'estimatedPomodoros': _estimatedPomodoros,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isCompleted': false,
      };

      context.read<ProjectBloc>().add(CreateTaskEvent(taskData));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Task'),
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
          onPressed: _createTask,
          child: const Text('Create'),
        ),
      ],
    );
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
