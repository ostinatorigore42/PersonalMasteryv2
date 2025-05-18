import 'package:flutter/material.dart';

class ProjectsTabContent extends StatefulWidget {
  const ProjectsTabContent({super.key});

  @override
  State<ProjectsTabContent> createState() => _ProjectsTabContentState();
}

class _ProjectsTabContentState extends State<ProjectsTabContent> {
  bool _showArchived = false;
  
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: _buildProjectList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateProjectDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  Widget _buildProjectList() {
    // Mock data for projects
    final projects = [
      {
        'id': '1',
        'name': 'Mobile App Design',
        'description': 'Design system and wireframes for the new mobile application',
        'color': Colors.blue,
        'isArchived': false,
        'activeTasks': 8,
      },
      {
        'id': '2',
        'name': 'Website Redesign',
        'description': 'Update the company website with a new look and feel',
        'color': Colors.green,
        'isArchived': false,
        'activeTasks': 5,
      },
      {
        'id': '3',
        'name': 'Marketing Campaign',
        'description': 'Q2 marketing campaign planning and execution',
        'color': Colors.purple,
        'isArchived': true,
        'activeTasks': 0,
      },
    ];
    
    // Filter projects based on archived status
    final filteredProjects = _showArchived 
        ? projects 
        : projects.where((p) => p['isArchived'] == false).toList();
    
    if (filteredProjects.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        
        return _ProjectCard(
          name: project['name'] as String,
          description: project['description'] as String,
          color: project['color'] as Color,
          isArchived: project['isArchived'] as bool,
          activeTasks: project['activeTasks'] as int,
          onTap: () {
            // Navigate to project detail
          },
          onEdit: () {
            // Show edit project dialog
          },
          onArchive: () {
            // Archive project
          },
          onDelete: () {
            // Delete project
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first project to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateProjectDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
        ],
      ),
    );
  }
  
  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateProjectDialog(),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String name;
  final String description;
  final Color color;
  final bool isArchived;
  final int activeTasks;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.name,
    required this.description,
    required this.color,
    required this.isArchived,
    required this.activeTasks,
    required this.onTap,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
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
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isArchived ? Colors.grey : null,
                        decoration: isArchived ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (isArchived)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ARCHIVED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
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
                  Text(
                    '$activeTasks active tasks',
                    style: TextStyle(
                      color: isArchived ? Colors.grey : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'archive') {
                        onArchive();
                      } else if (value == 'delete') {
                        onDelete();
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
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(isArchived ? Icons.unarchive : Icons.archive),
                            const SizedBox(width: 8),
                            Text(isArchived ? 'Unarchive' : 'Archive'),
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
  }
}

class _CreateProjectDialog extends StatefulWidget {
  const _CreateProjectDialog();

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Colors.blue;

  // Predefined colors in Apple/OpenAI style
  final List<Color> _colors = [
    const Color(0xFF007AFF), // iOS Blue
    const Color(0xFF34C759), // iOS Green
    const Color(0xFFFF9500), // iOS Orange
    const Color(0xFFFF2D55), // iOS Red
    const Color(0xFF5856D6), // iOS Purple
    const Color(0xFFAF52DE), // iOS Pink
    const Color(0xFF5AC8FA), // iOS Light Blue
    const Color(0xFFFFCC00), // iOS Yellow
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'Enter project name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter project description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'Project Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
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
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              // Create project
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}