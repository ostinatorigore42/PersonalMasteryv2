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

  Future<void> _showAddProjectDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Project'),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final project = Project(
                  id: '', // Firestore will generate the ID
                  name: nameController.text,
                  description: descriptionController.text,
                  createdAt: DateTime.now(),
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddProjectDialog,
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final projects = snapshot.data ?? [];
                if (projects.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No projects yet. Create your first project!',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                        // Navigate to project detail screen
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskListPage(projectId: project.id, projectName: project.name)));
                      },
                      onDelete: () => _firestoreService.deleteProject(project.id),
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