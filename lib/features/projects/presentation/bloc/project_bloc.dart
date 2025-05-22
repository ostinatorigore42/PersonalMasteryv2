import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/project_repository.dart';

// Events
abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {}

class LoadProjectDetailsEvent extends ProjectEvent {
  final String projectId;

  const LoadProjectDetailsEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class LoadTasksEvent extends ProjectEvent {
  final String projectId;
  final bool includeCompleted;

  const LoadTasksEvent({
    required this.projectId,
    this.includeCompleted = false,
  });

  @override
  List<Object?> get props => [projectId, includeCompleted];
}

class LoadTaskDetailsEvent extends ProjectEvent {
  final String taskId;

  const LoadTaskDetailsEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class CreateProjectEvent extends ProjectEvent {
  final Map<String, dynamic> projectData;

  const CreateProjectEvent(this.projectData);

  @override
  List<Object?> get props => [projectData];
}

class UpdateProjectEvent extends ProjectEvent {
  final String projectId;
  final Map<String, dynamic> updates;

  const UpdateProjectEvent(this.projectId, this.updates);

  @override
  List<Object?> get props => [projectId, updates];
}

class DeleteProjectEvent extends ProjectEvent {
  final String projectId;

  const DeleteProjectEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ArchiveProjectEvent extends ProjectEvent {
  final String projectId;

  const ArchiveProjectEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class CreateTaskEvent extends ProjectEvent {
  final Map<String, dynamic> taskData;

  const CreateTaskEvent(this.taskData);

  @override
  List<Object?> get props => [taskData];
}

class UpdateTaskEvent extends ProjectEvent {
  final String taskId;
  final Map<String, dynamic> updates;

  const UpdateTaskEvent(this.taskId, this.updates);

  @override
  List<Object?> get props => [taskId, updates];
}

class DeleteTaskEvent extends ProjectEvent {
  final String taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class CompleteTaskEvent extends ProjectEvent {
  final String taskId;
  final bool completed;

  const CompleteTaskEvent(this.taskId, this.completed);

  @override
  List<Object?> get props => [taskId, completed];
}

class MoveTaskEvent extends ProjectEvent {
  final String taskId;
  final String newProjectId;

  const MoveTaskEvent(this.taskId, this.newProjectId);

  @override
  List<Object?> get props => [taskId, newProjectId];
}

class LoadAvailableTagsEvent extends ProjectEvent {}

class SaveAvailableTagsEvent extends ProjectEvent {
  final List<String> tags;

  const SaveAvailableTagsEvent(this.tags);

  @override
  List<Object?> get props => [tags];
}

// States
abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  final List<Map<String, dynamic>> projects;

  const ProjectsLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectDetailsLoaded extends ProjectState {
  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> tasks;

  const ProjectDetailsLoaded({
    required this.project,
    required this.tasks,
  });

  @override
  List<Object?> get props => [project, tasks];
}

class TaskDetailsLoaded extends ProjectState {
  final Map<String, dynamic> task;

  const TaskDetailsLoaded(this.task);

  @override
  List<Object?> get props => [task];
}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

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
      emit(ProjectLoading());
      final projects = await projectRepository.getProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onLoadProjectDetails(
    LoadProjectDetailsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final project = await projectRepository.getProject(event.projectId);
      if (project != null) {
        add(LoadTasksEvent(projectId: event.projectId));
      } else {
        emit(ProjectError('Project not found'));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final project = await projectRepository.getProject(event.projectId);
      if (project != null) {
        final tasks = await projectRepository.getTasks(
          projectId: event.projectId,
          includeCompleted: event.includeCompleted,
        );
        emit(ProjectDetailsLoaded(project: project, tasks: tasks));
      } else {
        emit(ProjectError('Project not found'));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onLoadTaskDetails(
    LoadTaskDetailsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        emit(TaskDetailsLoaded(task));
      } else {
        emit(ProjectError('Task not found'));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.createProject(event.projectData);
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.updateProject(event.projectId, event.updates);
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.deleteProject(event.projectId);
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onArchiveProject(
    ArchiveProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.archiveProject(event.projectId);
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onCreateTask(
    CreateTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.createTask(event.taskData);
      add(LoadTasksEvent(projectId: event.taskData['projectId'] as String));
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.updateTask(event.taskId, event.updates);
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        add(LoadTasksEvent(projectId: task['projectId'] as String));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        final projectId = task['projectId'] as String;
        await projectRepository.deleteTask(event.taskId);
        add(LoadTasksEvent(projectId: projectId));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onCompleteTask(
    CompleteTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.updateTask(
        event.taskId,
        {'completed': event.completed},
      );
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        add(LoadTasksEvent(projectId: task['projectId'] as String));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onMoveTask(
    MoveTaskEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final task = await projectRepository.getTask(event.taskId);
      if (task != null) {
        final oldProjectId = task['projectId'] as String;
        await projectRepository.updateTask(
          event.taskId,
          {'projectId': event.newProjectId},
        );
        add(LoadTasksEvent(projectId: oldProjectId));
        add(LoadTasksEvent(projectId: event.newProjectId));
      }
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onLoadAvailableTags(
    LoadAvailableTagsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      final tags = await projectRepository.getAvailableTags();
      emit(ProjectsLoaded([])); // TODO: Create a proper state for tags
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }

  Future<void> _onSaveAvailableTags(
    SaveAvailableTagsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      emit(ProjectLoading());
      await projectRepository.saveAvailableTags(event.tags);
      add(LoadAvailableTagsEvent());
    } catch (e) {
      emit(ProjectError(e.toString()));
    }
  }
}
