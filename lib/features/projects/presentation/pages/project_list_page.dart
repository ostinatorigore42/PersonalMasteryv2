import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/services/firebase_service.dart'; // Import FirebaseService
import '../../../../models/task.dart'; // Import Task model
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/project_bloc.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  bool _showArchived = false;
  late final FirebaseService _firebaseService; // Initialize FirebaseService

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService.instance; // Get instance
    _loadProjects();
  }

  void _loadProjects() {
    context.read<ProjectBloc>().add(LoadProjectsEvent());
  }

  void _createProject() {
    showDialog(
      context: context,
      builder: (context) => _CreateProjectDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Tasks'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
              _loadProjects();
            },
          ),
        ],
      ),
      body: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
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
          } else if (state is ProjectsLoaded) {
            final projects = state.projects;

            if (projects.isEmpty) {
              return _buildEmptyState();
            }

            return _buildProjectList(projects);
          } else {
            return _buildEmptyState();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first project to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Project',
            onPressed: _createProject,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<Map<String, dynamic>> projects) {
    // Filter projects based on archive status
    final filteredProjects = _showArchived 
        ? projects 
        : projects.where((p) => p['isArchived'] != true).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        final projectId = project['id'] as String;
        final projectName = project['name'] as String;
        final projectDescription = project['description'] as String?;
        final colorHex = project['color'] as String? ?? '#2196F3';
        final isArchived = project['isArchived'] as bool? ?? false;
        
        // Convert hex color to Color
        final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isArchived ? Colors.grey.shade300 : color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              context.read<ProjectBloc>().add(LoadProjectDetailsEvent(projectId));
              Navigator.of(context).pushNamed(
                RouteConstants.projectDetail,
                arguments: {'projectId': projectId},
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          projectName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isArchived ? Colors.grey : null,
                            decoration: isArchived ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isArchived)
                        const Chip(
                          label: Text('Archived'),
                          backgroundColor: Colors.grey,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                  if (projectDescription != null && projectDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      projectDescription,
                      style: TextStyle(
                        color: isArchived ? Colors.grey : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Use StreamBuilder to get tasks and calculate stats
                      StreamBuilder<QuerySnapshot>(
                        stream: _firebaseService.getUserCollection(
                          'projects/${projectId}/tasks',
                        ).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(); // Or a loading indicator
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          final tasks = snapshot.data?.docs.map((doc) => Task.fromFirestore(doc)).toList() ?? [];

                          final ongoingTasks = tasks.where((task) => !task.completed).length;
                          final totalElapsedTime = tasks.fold(0, (sum, task) => sum + task.elapsedTime);

                          return Row(
                            children: [
                              Text(
                                _formatDuration(totalElapsedTime),
                                style: TextStyle(
                                  color: isArchived ? Colors.grey : color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$ongoingTasks active tasks',
                                style: TextStyle(
                                  color: isArchived ? Colors.grey : color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final projectData = await context.read<ProjectBloc>().projectRepository.getProject(projectId);
                            if (projectData != null) {
                              showDialog(
                                context: context,
                                builder: (context) => _EditProjectDialog(
                                  projectId: projectId,
                                  initialData: projectData,
                                ),
                              );
                            }
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
                          if (!isArchived)
                            const PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(Icons.archive),
                                  SizedBox(width: 8),
                                  Text('Archive'),
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
                                  Text('Unarchive'),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _CreateProjectDialog extends StatefulWidget {
  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#2196F3'; // Default blue color

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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createProject() {
    if (_formKey.currentState?.validate() ?? false) {
      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'color': _selectedColor,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isArchived': false,
      };

      context.read<ProjectBloc>().add(CreateProjectEvent(projectData));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
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
          onPressed: _createProject,
          child: const Text('Create'),
        ),
      ],
    );
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
