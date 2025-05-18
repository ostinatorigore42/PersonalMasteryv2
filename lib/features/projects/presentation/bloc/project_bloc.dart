import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../domain/repositories/project_repository.dart';

// Events
@immutable
abstract class ProjectEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {}

class LoadProjectDetailsEvent extends ProjectEvent {
  final String projectId;
  
  LoadProjectDetailsEvent(this.projectId);
  
  @override
  List<Object?> get props => [projectId];
}

class LoadTasksEvent extends ProjectEvent {
  final String? projectId;
  final bool includeCompleted;
  
  LoadTasksEvent({this.projectId, this.includeCompleted = false});
  
  @override
  List<Object?> get props => [projectId, includeCompleted];
}

class LoadTaskDetailsEvent extends ProjectEvent {
  final String taskId;
  
  LoadTaskDetailsEvent(this.taskId);
  
  @override
  List<Object?> get props => [taskId];
}

class CreateProjectEvent extends ProjectEvent {
  final Map<String, dynamic> projectData;
  
  CreateProjectEvent(this.projectData);
  
  @override
  List<Object?> get props => [projectData];
}

class UpdateProjectEvent extends ProjectEvent {
  final String projectId;
  final Map<String, dynamic> updates;
  
  UpdateProjectEvent(this.projectId, this.updates);
  
  @override
  List<Object?> get props => [projectId, updates];
}

class DeleteProjectEvent extends ProjectEvent {
  final String projectId;
  
  DeleteProjectEvent(this.projectId);
  
  @override
  List<Object?> get props => [projectId];
}

class ArchiveProjectEvent extends ProjectEvent {
  final String projectId;
  
  ArchiveProjectEvent(this.projectId);
  
  @override
  List<Object?> get props => [projectId];
}

class CreateTaskEvent extends ProjectEvent {
  final Map<String, dynamic> taskData;
  
  CreateTaskEvent(this.taskData);
  
  @override
  List<Object?> get props => [taskData];
}

class UpdateTaskEvent extends ProjectEvent {
  final String taskId;
  final Map<String, dynamic> updates;
  
  UpdateTaskEvent(this.taskId, this.updates);
  
  @override
  List<Object?> get props => [taskId, updates];
}

class DeleteTaskEvent extends ProjectEvent {
  final String taskId;
  
  DeleteTaskEvent(this.taskId);
  
  @override
  List<Object?> get props => [taskId];
}

class CompleteTaskEvent extends ProjectEvent {
  final String taskId;
  
  CompleteTaskEvent(this.taskId);
  
  @override
  List<Object?> get props => [taskId];
}

class MoveTaskEvent extends ProjectEvent {
  final String taskId;
  final String newProjectId;
  
  MoveTaskEvent(this.taskId, this.newProjectId);
  
  @override
  List<Object?> get props => [taskId, newProjectId];
}

class LoadAvailableTagsEvent extends ProjectEvent {}

class SaveAvailableTagsEvent extends ProjectEvent {
  final List<String> tags;
  
  SaveAvailableTagsEvent(this.tags);
  
  @override
  List<Object?> get props => [tags];
}

// States
@immutable
abstract class ProjectState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectsLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  final List<Map<String, dynamic>> projects;
  final bool includeArchived;
  
  ProjectsLoaded(this.projects, {this.includeArchived = false});
  
  @override
  List<Object?> get props => [projects, includeArchived];
}

class ProjectDetailsLoaded extends ProjectState {
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> tasks;
  
  ProjectDetailsLoaded(this.project, this.tasks);
  
  @override
  List<Object?> get props => [project, tasks];
}

class TasksLoaded extends ProjectState {
  final List<Map<String, dynamic>> tasks;
  final String? projectId;
  final bool includeCompleted;
  
  TasksLoaded(this.tasks, {this.projectId, this.includeCompleted = false});
  
  @override
  List<Object?> get props => [tasks, projectId, includeCompleted];
}

class TaskDetailsLoaded extends ProjectState {
  final Map<String, dynamic> task;
  final Map<String, dynamic>? project;
  
  TaskDetailsLoaded(this.task, this.project);
  
  @override
  List<Object?> get props => [task, project];
}

class ProjectActionSuccess extends ProjectState {
  final String message;
  
  ProjectActionSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class TaskActionSuccess extends ProjectState {
  final String message;
  
  TaskActionSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AvailableTagsLoaded extends ProjectState {
  final List<String> tags;
  
  AvailableTagsLoaded(this.tags);
  
  @override
  List<Object?> get props => [tags];
}

class ProjectError extends ProjectState {
  final String message;
  
  ProjectError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository projectRepository;
  
  ProjectBloc({required this.projectRepository}) : super(ProjectInitial()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<LoadProjectDetailsEvent>(_onLoadProjectDetails);
    on<LoadTasksEvent>(_onLoadTasks);
    on<LoadTaskDetailsEvent>(_onLoadTaskDetails);
    on<CreateProjectEvent>(_onCreateProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<ArchiveProjectEvent>(_onArchiveProject);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<CompleteTaskEvent>(_onCompleteTask);
    on<MoveTaskEvent>(_onMoveTask);
    on<LoadAvailableTagsEvent>(_onLoadAvailableTags);
    on<SaveAvailableTagsEvent>(_onSaveAvailableTags);
  }
  
  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectsLoading());
      
      final projects = await projectRepository.getProjects();
      
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectError('Failed to load projects: $e'));
    }
  }
  
  Future<void> _onLoadProjectDetails(
    LoadProjectDetailsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectsLoading());
      
      final project = await projectRepository.getProject(event.projectId);
      
      if (project == null) {
        emit(ProjectError('Project not found'));
        return;
      }
      
      final tasks = await projectRepository.getTasks(projectId: event.projectId);
      
      emit(ProjectDetailsLoaded(project, tasks));
    } catch (e) {
      emit(ProjectError('Failed to load project details: $e'));
    }
  }
  
  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectsLoading());
      
      final tasks = await projectRepository.getTasks(
        projectId: event.projectId,
        includeCompleted: event.includeCompleted,
      );
      
      emit(TasksLoaded(
        tasks,
        projectId: event.projectId,
        includeCompleted: event.includeCompleted,
      ));
    } catch (e) {
      emit(ProjectError('Failed to load tasks: $e'));
    }
  }
  
  Future<void> _onLoadTaskDetails(
    LoadTaskDetailsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectsLoading());
      
      final task = await projectRepository.getTask(event.taskId);
      
      if (task == null) {
        emit(ProjectError('Task not found'));
        return;
      }
      
      final projectId = task['projectId'] as String;
      final project = await projectRepository.getProject(projectId);
      
      emit(TaskDetailsLoaded(task, project));
    } catch (e) {
      emit(ProjectError('Failed to load task details: $e'));
    }
  }
  
  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final projectId = await projectRepository.createProject(event.projectData);
      
      emit(ProjectActionSuccess('Project created successfully'));
      
      // Reload projects
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Failed to create project: $e'));
    }
  }
  
  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.updateProject(event.projectId, event.updates);
      
      emit(ProjectActionSuccess('Project updated successfully'));
      
      // Reload project details
      add(LoadProjectDetailsEvent(event.projectId));
    } catch (e) {
      emit(ProjectError('Failed to update project: $e'));
    }
  }
  
  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.deleteProject(event.projectId);
      
      emit(ProjectActionSuccess('Project deleted successfully'));
      
      // Reload projects
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Failed to delete project: $e'));
    }
  }
  
  Future<void> _onArchiveProject(
    ArchiveProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.archiveProject(event.projectId);
      
      emit(ProjectActionSuccess('Project archived successfully'));
      
      // Reload projects
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Failed to archive project: $e'));
    }
  }
  
  Future<void> _onCreateTask(
    CreateTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final taskId = await projectRepository.createTask(event.taskData);
      
      emit(TaskActionSuccess('Task created successfully'));
      
      // Reload tasks for the project
      add(LoadTasksEvent(projectId: event.taskData['projectId'] as String));
    } catch (e) {
      emit(ProjectError('Failed to create task: $e'));
    }
  }
  
  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.updateTask(event.taskId, event.updates);
      
      emit(TaskActionSuccess('Task updated successfully'));
      
      // Get task data to know which project to reload
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        final projectId = task['projectId'] as String;
        add(LoadTasksEvent(projectId: projectId));
      }
    } catch (e) {
      emit(ProjectError('Failed to update task: $e'));
    }
  }
  
  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      // Get task data to know which project to reload
      final task = await projectRepository.getTask(event.taskId);
      String? projectId;
      
      if (task != null) {
        projectId = task['projectId'] as String;
      }
      
      await projectRepository.deleteTask(event.taskId);
      
      emit(TaskActionSuccess('Task deleted successfully'));
      
      // Reload tasks for the project
      if (projectId != null) {
        add(LoadTasksEvent(projectId: projectId));
      }
    } catch (e) {
      emit(ProjectError('Failed to delete task: $e'));
    }
  }
  
  Future<void> _onCompleteTask(
    CompleteTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.completeTask(event.taskId);
      
      emit(TaskActionSuccess('Task completed successfully'));
      
      // Get task data to know which project to reload
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        final projectId = task['projectId'] as String;
        add(LoadTasksEvent(projectId: projectId, includeCompleted: true));
      }
    } catch (e) {
      emit(ProjectError('Failed to complete task: $e'));
    }
  }
  
  Future<void> _onMoveTask(
    MoveTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      // Get task data to know which project to reload
      final task = await projectRepository.getTask(event.taskId);
      String? oldProjectId;
      
      if (task != null) {
        oldProjectId = task['projectId'] as String;
      }
      
      await projectRepository.moveTaskToProject(event.taskId, event.newProjectId);
      
      emit(TaskActionSuccess('Task moved successfully'));
      
      // Reload tasks for both projects
      if (oldProjectId != null) {
        add(LoadTasksEvent(projectId: oldProjectId));
      }
      add(LoadTasksEvent(projectId: event.newProjectId));
    } catch (e) {
      emit(ProjectError('Failed to move task: $e'));
    }
  }
  
  Future<void> _onLoadAvailableTags(
    LoadAvailableTagsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final tags = await projectRepository.getAvailableTags();
      
      emit(AvailableTagsLoaded(tags));
    } catch (e) {
      emit(ProjectError('Failed to load available tags: $e'));
    }
  }
  
  Future<void> _onSaveAvailableTags(
    SaveAvailableTagsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await projectRepository.saveAvailableTags(event.tags);
      
      emit(AvailableTagsLoaded(event.tags));
      emit(ProjectActionSuccess('Tags updated successfully'));
    } catch (e) {
      emit(ProjectError('Failed to save available tags: $e'));
    }
  }
}
