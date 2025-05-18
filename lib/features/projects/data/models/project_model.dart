import 'package:hive/hive.dart';

/// Model representing a project
class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final List<String>? taskIds;
  final String? parentId; // For nested projects (areas)
  
  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.taskIds,
    this.parentId,
  });
  
  // Convert to Map for Firebase storage
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isArchived': isArchived,
      'taskIds': taskIds,
      'parentId': parentId,
    };
  }
  
  // Create from Firebase data
  factory ProjectModel.fromFirebase(String id, Map<String, dynamic> data) {
    return ProjectModel(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String?,
      color: data['color'] as String,
      createdAt: (data['createdAt'] as dynamic).toDate(),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
      isArchived: data['isArchived'] as bool? ?? false,
      taskIds: data['taskIds'] != null ? List<String>.from(data['taskIds']) : null,
      parentId: data['parentId'] as String?,
    );
  }
  
  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'taskIds': taskIds,
      'parentId': parentId,
    };
  }
  
  // Create from local storage Map
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      taskIds: json['taskIds'] != null ? List<String>.from(json['taskIds']) : null,
      parentId: json['parentId'] as String?,
    );
  }
  
  // Copy with method for updating properties
  ProjectModel copyWith({
    String? name,
    String? description,
    String? color,
    DateTime? updatedAt,
    bool? isArchived,
    List<String>? taskIds,
    String? parentId,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      taskIds: taskIds ?? this.taskIds,
      parentId: parentId ?? this.parentId,
    );
  }
  
  // Add a task ID to the project
  ProjectModel addTask(String taskId) {
    final currentTaskIds = taskIds ?? [];
    if (!currentTaskIds.contains(taskId)) {
      return copyWith(
        taskIds: [...currentTaskIds, taskId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }
  
  // Remove a task ID from the project
  ProjectModel removeTask(String taskId) {
    final currentTaskIds = taskIds ?? [];
    if (currentTaskIds.contains(taskId)) {
      return copyWith(
        taskIds: currentTaskIds.where((id) => id != taskId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }
}
