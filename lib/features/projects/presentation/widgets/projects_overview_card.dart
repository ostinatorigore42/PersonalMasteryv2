import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/project.dart';
import '../../../../services/firestore_service.dart';
import '../../../../widgets/project_item_card.dart';
import '../../../tasks/presentation/pages/task_list_page.dart'; // Assuming a task list page exists or will be created here

class ProjectsOverviewCard extends StatefulWidget {
  const ProjectsOverviewCard({Key? key}) : super(key: key);

  @override
  State<ProjectsOverviewCard> createState() => _ProjectsOverviewCardState();
}

class _ProjectsOverviewCardState extends State<ProjectsOverviewCard> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showEditProjectDialog(Project project) async {
    final TextEditingController nameController = TextEditingController(text: project.name);
    final TextEditingController descriptionController = TextEditingController(text: project.description);
    String selectedColor = project.color ?? '#2196F3';

    final List<String> colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FFC107', // Amber
      '#F44336', // Red
      '#9C27B0', // Purple
      '#FF9800', // Orange
      '#795548', // Brown
      '#607D8B', // Blue Grey
      '#E91E63', // Pink
      '#00BCD4', // Cyan
    ];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Project Description'),
                ),
                const SizedBox(height: 16),
                const Text('Project Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedProject = Project(
                    id: project.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    createdAt: project.createdAt,
                    userId: project.userId,
                    color: selectedColor,
                  );
                  await _firestoreService.updateProject(updatedProject);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(String projectId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteProject(projectId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProjectDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedColor = '#2196F3'; // Default color

    final List<String> colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FFC107', // Amber
      '#F44336', // Red
      '#9C27B0', // Purple
      '#FF9800', // Orange
      '#795548', // Brown
      '#607D8B', // Blue Grey
      '#E91E63', // Pink
      '#00BCD4', // Cyan
    ];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Project Description'),
                ),
                const SizedBox(height: 16),
                const Text('Project Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  // Use Timestamp.now() when creating a new project for Firestore
                  final project = Project(
                    id: '', // Firestore will generate the ID
                    name: nameController.text,
                    description: descriptionController.text,
                    createdAt: DateTime.now(), // Keep DateTime for the model
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    color: selectedColor,
                  );
                  // The toMap method in the Project model will convert DateTime to Timestamp
                  await _firestoreService.addProject(project);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black, size: 24.0),
                  onPressed: _showAddProjectDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Project>>(
              stream: _firestoreService.getProjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No projects yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showAddProjectDialog,
                          child: const Text('Create Your First Project'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ProjectItemCard(
                      project: project,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskListPage(
                              projectId: project.id,
                              projectName: project.name,
                            ),
                          ),
                        );
                      },
                      onEdit: () => _showEditProjectDialog(project),
                      onDelete: () => _showDeleteConfirmationDialog(project.id),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 