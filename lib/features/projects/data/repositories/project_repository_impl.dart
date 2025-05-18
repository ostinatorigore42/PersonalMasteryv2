import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();
  
  ProjectRepositoryImpl(
    this._firebaseService,
    this._localStorageService,
    this._syncService,
  );
  
  // Project methods
  @override
  Future<List<Map<String, dynamic>>> getProjects({bool includeArchived = false}) async {
    try {
      final projects = _localStorageService.getAllItems(AppConstants.projectsBox);
      
      if (!includeArchived) {
        return projects.where((project) => project['isArchived'] != true).toList();
      }
      
      return projects;
    } catch (e) {
      print('Error getting projects: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    try {
      return _localStorageService.getItem(AppConstants.projectsBox, projectId);
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }
  
  @override
  Future<String> createProject(Map<String, dynamic> projectData) async {
    try {
      final now = DateTime.now();
      final projectId = _uuid.v4();
      
      // Set default values if not provided
      projectData['createdAt'] ??= now.toIso8601String();
      projectData['updatedAt'] ??= now.toIso8601String();
      projectData['color'] ??= '#2196F3'; // Default to blue
      projectData['isArchived'] ??= false;
      
      // Create project model
      final projectModel = ProjectModel(
        id: projectId,
        name: projectData['name'] as String,
        description: projectData['description'] as String?,
        color: projectData['color'] as String,
        createdAt: now,
        updatedAt: now,
        isArchived: projectData['isArchived'] as bool,
        parentId: projectData['parentId'] as String?,
      );
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.projectsBox,
        projectId,
        projectModel.toJson(),
      );
      
      // Trigger sync
      _syncService.sync();
      
      return projectId;
    } catch (e) {
      print('Error creating project: $e');
      throw Exception('Failed to create project: $e');
    }
  }
  
  @override
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    try {
      // Get current project data
      final projectData = await getProject(projectId);
      if (projectData == null) {
        throw Exception('Project not found');
      }
      
      // Update fields
      final now = DateTime.now();
      updates['updatedAt'] = now.toIso8601String();
      
      final updatedData = {
        ...projectData,
        ...updates,
      };
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.projectsBox,
        projectId,
        updatedData,
      );
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error updating project: $e');
      throw Exception('Failed to update project: $e');
    }
  }
  
  @override
  Future<void> deleteProject(String projectId) async {
    try {
      // Get tasks for this project
      final tasks = await getTasks(projectId: projectId);
      
      // Delete all tasks
      for (final task in tasks) {
        await deleteTask(task['id'] as String);
      }
      
      // Delete project from local storage
      await _localStorageService.deleteItem(AppConstants.projectsBox, projectId);
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error deleting project: $e');
      throw Exception('Failed to delete project: $e');
    }
  }
  
  @override
  Future<void> archiveProject(String projectId) async {
    try {
      await updateProject(projectId, {'isArchived': true});
    } catch (e) {
      print('Error archiving project: $e');
      throw Exception('Failed to archive project: $e');
    }
  }
  
  // Task methods
  @override
  Future<List<Map<String, dynamic>>> getTasks({String? projectId, bool includeCompleted = false}) async {
    try {
      final tasks = _localStorageService.getAllItems(AppConstants.tasksBox);
      
      // Filter by project if provided
      List<Map<String, dynamic>> filteredTasks = tasks;
      if (projectId != null) {
        filteredTasks = tasks.where((task) => task['projectId'] == projectId).toList();
      }
      
      // Filter out completed tasks if needed
      if (!includeCompleted) {
        filteredTasks = filteredTasks.where((task) => task['isCompleted'] != true).toList();
      }
      
      // Sort by due date (null dates at the end) and then by priority
      filteredTasks.sort((a, b) {
        // First by completion status
        final aCompleted = a['isCompleted'] as bool? ?? false;
        final bCompleted = b['isCompleted'] as bool? ?? false;
        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }
        
        // Then by due date
        final aDueDate = a['dueDate'] != null ? DateTime.parse(a['dueDate'] as String) : null;
        final bDueDate = b['dueDate'] != null ? DateTime.parse(b['dueDate'] as String) : null;
        
        if (aDueDate != null && bDueDate != null) {
          return aDueDate.compareTo(bDueDate);
        } else if (aDueDate != null) {
          return -1;
        } else if (bDueDate != null) {
          return 1;
        }
        
        // Then by priority
        final aPriority = a['priority'] as String? ?? 'medium';
        final bPriority = b['priority'] as String? ?? 'medium';
        
        final aPriorityValue = aPriority == 'high' ? 3 : (aPriority == 'medium' ? 2 : 1);
        final bPriorityValue = bPriority == 'high' ? 3 : (bPriority == 'medium' ? 2 : 1);
        
        return bPriorityValue - aPriorityValue;
      });
      
      return filteredTasks;
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getTask(String taskId) async {
    try {
      return _localStorageService.getItem(AppConstants.tasksBox, taskId);
    } catch (e) {
      print('Error getting task: $e');
      return null;
    }
  }
  
  @override
  Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      final now = DateTime.now();
      final taskId = _uuid.v4();
      
      // Set default values if not provided
      taskData['createdAt'] ??= now.toIso8601String();
      taskData['updatedAt'] ??= now.toIso8601String();
      taskData['isCompleted'] ??= false;
      taskData['priority'] ??= 'medium';
      
      // Create task model
      final taskModel = TaskModel(
        id: taskId,
        title: taskData['title'] as String,
        description: taskData['description'] as String?,
        projectId: taskData['projectId'] as String,
        createdAt: now,
        updatedAt: now,
        dueDate: taskData['dueDate'] != null ? DateTime.parse(taskData['dueDate'] as String) : null,
        isCompleted: taskData['isCompleted'] as bool,
        priority: taskData['priority'] as String,
        tags: taskData['tags'] != null ? List<String>.from(taskData['tags'] as List) : null,
        goalId: taskData['goalId'] as String?,
        estimatedPomodoros: taskData['estimatedPomodoros'] as int?,
      );
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.tasksBox,
        taskId,
        taskModel.toJson(),
      );
      
      // Update project to include this task
      final projectData = await getProject(taskData['projectId'] as String);
      if (projectData != null) {
        final taskIds = projectData['taskIds'] != null
            ? List<String>.from(projectData['taskIds'] as List)
            : <String>[];
        
        if (!taskIds.contains(taskId)) {
          taskIds.add(taskId);
          await updateProject(taskData['projectId'] as String, {'taskIds': taskIds});
        }
      }
      
      // Trigger sync
      _syncService.sync();
      
      return taskId;
    } catch (e) {
      print('Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }
  
  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      // Get current task data
      final taskData = await getTask(taskId);
      if (taskData == null) {
        throw Exception('Task not found');
      }
      
      // Check if project is being changed
      final oldProjectId = taskData['projectId'] as String;
      final newProjectId = updates['projectId'] as String?;
      
      // Update fields
      final now = DateTime.now();
      updates['updatedAt'] = now.toIso8601String();
      
      final updatedData = {
        ...taskData,
        ...updates,
      };
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.tasksBox,
        taskId,
        updatedData,
      );
      
      // Handle project change if needed
      if (newProjectId != null && oldProjectId != newProjectId) {
        // Remove task from old project
        final oldProjectData = await getProject(oldProjectId);
        if (oldProjectData != null && oldProjectData['taskIds'] != null) {
          final oldTaskIds = List<String>.from(oldProjectData['taskIds'] as List);
          oldTaskIds.remove(taskId);
          await updateProject(oldProjectId, {'taskIds': oldTaskIds});
        }
        
        // Add task to new project
        final newProjectData = await getProject(newProjectId);
        if (newProjectData != null) {
          final newTaskIds = newProjectData['taskIds'] != null
              ? List<String>.from(newProjectData['taskIds'] as List)
              : <String>[];
          
          if (!newTaskIds.contains(taskId)) {
            newTaskIds.add(taskId);
            await updateProject(newProjectId, {'taskIds': newTaskIds});
          }
        }
      }
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }
  
  @override
  Future<void> deleteTask(String taskId) async {
    try {
      // Get task data
      final taskData = await getTask(taskId);
      if (taskData == null) {
        throw Exception('Task not found');
      }
      
      // Remove task from project
      final projectId = taskData['projectId'] as String;
      final projectData = await getProject(projectId);
      if (projectData != null && projectData['taskIds'] != null) {
        final taskIds = List<String>.from(projectData['taskIds'] as List);
        taskIds.remove(taskId);
        await updateProject(projectId, {'taskIds': taskIds});
      }
      
      // Delete task from local storage
      await _localStorageService.deleteItem(AppConstants.tasksBox, taskId);
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }
  
  @override
  Future<void> completeTask(String taskId) async {
    try {
      await updateTask(taskId, {
        'isCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error completing task: $e');
      throw Exception('Failed to complete task: $e');
    }
  }
  
  @override
  Future<void> moveTaskToProject(String taskId, String newProjectId) async {
    try {
      await updateTask(taskId, {'projectId': newProjectId});
    } catch (e) {
      print('Error moving task: $e');
      throw Exception('Failed to move task: $e');
    }
  }
  
  // Task tag methods
  @override
  Future<List<String>> getAvailableTags() async {
    try {
      final tagsData = _localStorageService.getItem(
        AppConstants.settingsBox,
        'availableTags',
      );
      
      if (tagsData != null && tagsData['tags'] != null) {
        return List<String>.from(tagsData['tags'] as List);
      }
      
      // Return default tags if none found
      return AppConstants.defaultTags;
    } catch (e) {
      print('Error getting available tags: $e');
      return AppConstants.defaultTags;
    }
  }
  
  @override
  Future<void> saveAvailableTags(List<String> tags) async {
    try {
      await _localStorageService.saveItem(
        AppConstants.settingsBox,
        'availableTags',
        {'tags': tags},
      );
    } catch (e) {
      print('Error saving available tags: $e');
      throw Exception('Failed to save available tags: $e');
    }
  }
  
  // Utility methods
  @override
  Future<int> getTasksCountForProject(String projectId, {bool onlyIncomplete = true}) async {
    try {
      final tasks = await getTasks(
        projectId: projectId,
        includeCompleted: !onlyIncomplete,
      );
      
      return tasks.length;
    } catch (e) {
      print('Error getting tasks count: $e');
      return 0;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTasksWithUpcomingDeadlines({int daysAhead = 7}) async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.add(Duration(days: daysAhead));
      
      final tasks = await getTasks(includeCompleted: false);
      
      // Filter tasks with due dates within the specified range
      return tasks.where((task) {
        if (task['dueDate'] == null) return false;
        
        final dueDate = DateTime.parse(task['dueDate'] as String);
        return dueDate.isAfter(now) && dueDate.isBefore(cutoffDate);
      }).toList();
    } catch (e) {
      print('Error getting tasks with upcoming deadlines: $e');
      return [];
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getRecentTasks({int limit = 10}) async {
    try {
      final tasks = await getTasks(includeCompleted: true);
      
      // Sort by updated time (most recent first)
      tasks.sort((a, b) {
        final aUpdated = DateTime.parse(a['updatedAt'] as String);
        final bUpdated = DateTime.parse(b['updatedAt'] as String);
        return bUpdated.compareTo(aUpdated);
      });
      
      // Limit the number of tasks
      return tasks.take(limit).toList();
    } catch (e) {
      print('Error getting recent tasks: $e');
      return [];
    }
  }
}
