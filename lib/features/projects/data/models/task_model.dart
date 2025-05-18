import 'package:hive/hive.dart';

/// Model representing a task
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String projectId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final String priority; // 'low', 'medium', 'high'
  final List<String>? tags;
  final List<String>? pomodoroSessionIds;
  final List<String>? subtaskIds;
  final String? goalId; // Associated goal ID
  final Map<String, dynamic>? notes; // Additional notes or custom fields
  final int? estimatedPomodoros;
  final int? completedPomodoros;
  
  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.projectId,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 'medium',
    this.tags,
    this.pomodoroSessionIds,
    this.subtaskIds,
    this.goalId,
    this.notes,
    this.estimatedPomodoros,
    this.completedPomodoros,
  });
  
  // Convert to Map for Firebase storage
  Map<String, dynamic> toFirebase() {
    return {
      'title': title,
      'description': description,
      'projectId': projectId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
      'priority': priority,
      'tags': tags,
      'pomodoroSessionIds': pomodoroSessionIds,
      'subtaskIds': subtaskIds,
      'goalId': goalId,
      'notes': notes,
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
    };
  }
  
  // Create from Firebase data
  factory TaskModel.fromFirebase(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String?,
      projectId: data['projectId'] as String,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as dynamic).toDate() : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: data['priority'] as String? ?? 'medium',
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      pomodoroSessionIds: data['pomodoroSessionIds'] != null 
          ? List<String>.from(data['pomodoroSessionIds']) 
          : null,
      subtaskIds: data['subtaskIds'] != null ? List<String>.from(data['subtaskIds']) : null,
      goalId: data['goalId'] as String?,
      notes: data['notes'] as Map<String, dynamic>?,
      estimatedPomodoros: data['estimatedPomodoros'] as int?,
      completedPomodoros: data['completedPomodoros'] as int?,
    );
  }
  
  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority,
      'tags': tags,
      'pomodoroSessionIds': pomodoroSessionIds,
      'subtaskIds': subtaskIds,
      'goalId': goalId,
      'notes': notes,
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
    };
  }
  
  // Create from local storage Map
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      projectId: json['projectId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      pomodoroSessionIds: json['pomodoroSessionIds'] != null 
          ? List<String>.from(json['pomodoroSessionIds']) 
          : null,
      subtaskIds: json['subtaskIds'] != null ? List<String>.from(json['subtaskIds']) : null,
      goalId: json['goalId'] as String?,
      notes: json['notes'] as Map<String, dynamic>?,
      estimatedPomodoros: json['estimatedPomodoros'] as int?,
      completedPomodoros: json['completedPomodoros'] as int?,
    );
  }
  
  // Copy with method for updating properties
  TaskModel copyWith({
    String? title,
    String? description,
    String? projectId,
    DateTime? updatedAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    List<String>? tags,
    List<String>? pomodoroSessionIds,
    List<String>? subtaskIds,
    String? goalId,
    Map<String, dynamic>? notes,
    int? estimatedPomodoros,
    int? completedPomodoros,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      pomodoroSessionIds: pomodoroSessionIds ?? this.pomodoroSessionIds,
      subtaskIds: subtaskIds ?? this.subtaskIds,
      goalId: goalId ?? this.goalId,
      notes: notes ?? this.notes,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    );
  }
  
  // Add a pomodoro session ID to the task
  TaskModel addPomodoroSession(String sessionId) {
    final currentSessionIds = pomodoroSessionIds ?? [];
    if (!currentSessionIds.contains(sessionId)) {
      return copyWith(
        pomodoroSessionIds: [...currentSessionIds, sessionId],
        updatedAt: DateTime.now(),
        completedPomodoros: (completedPomodoros ?? 0) + 1,
      );
    }
    return this;
  }
  
  // Add a subtask ID to the task
  TaskModel addSubtask(String subtaskId) {
    final currentSubtaskIds = subtaskIds ?? [];
    if (!currentSubtaskIds.contains(subtaskId)) {
      return copyWith(
        subtaskIds: [...currentSubtaskIds, subtaskId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }
  
  // Remove a subtask ID from the task
  TaskModel removeSubtask(String subtaskId) {
    final currentSubtaskIds = subtaskIds ?? [];
    if (currentSubtaskIds.contains(subtaskId)) {
      return copyWith(
        subtaskIds: currentSubtaskIds.where((id) => id != subtaskId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }
  
  // Calculate the progress of the task based on completed pomodoros
  double? get progress {
    if (estimatedPomodoros == null || estimatedPomodoros == 0) return null;
    final completed = completedPomodoros ?? 0;
    return completed / estimatedPomodoros!;
  }
}
