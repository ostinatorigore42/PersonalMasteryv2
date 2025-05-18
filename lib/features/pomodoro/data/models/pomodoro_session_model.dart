import 'package:hive/hive.dart';

/// Model representing a pomodoro session
class PomodoroSessionModel {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime endTime;
  final double? rating;
  final Map<String, dynamic>? notes;
  final bool isCompleted;
  final int durationMinutes;
  final String? projectId;
  
  PomodoroSessionModel({
    required this.id,
    required this.taskId,
    required this.startTime,
    required this.endTime,
    this.rating,
    this.notes,
    required this.isCompleted,
    required this.durationMinutes,
    this.projectId,
  });
  
  // Convert to Map for Firebase storage
  Map<String, dynamic> toFirebase() {
    return {
      'taskId': taskId,
      'startTime': startTime,
      'endTime': endTime,
      'rating': rating,
      'notes': notes,
      'isCompleted': isCompleted,
      'durationMinutes': durationMinutes,
      'projectId': projectId,
    };
  }
  
  // Create from Firebase data
  factory PomodoroSessionModel.fromFirebase(String id, Map<String, dynamic> data) {
    return PomodoroSessionModel(
      id: id,
      taskId: data['taskId'] as String,
      startTime: (data['startTime'] as dynamic).toDate(),
      endTime: (data['endTime'] as dynamic).toDate(),
      rating: data['rating'] as double?,
      notes: data['notes'] as Map<String, dynamic>?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      durationMinutes: data['durationMinutes'] as int,
      projectId: data['projectId'] as String?,
    );
  }
  
  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'rating': rating,
      'notes': notes,
      'isCompleted': isCompleted,
      'durationMinutes': durationMinutes,
      'projectId': projectId,
    };
  }
  
  // Create from local storage Map
  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) {
    return PomodoroSessionModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      rating: json['rating'] as double?,
      notes: json['notes'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      durationMinutes: json['durationMinutes'] as int,
      projectId: json['projectId'] as String?,
    );
  }
  
  // Copy with method for updating properties
  PomodoroSessionModel copyWith({
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    double? rating,
    Map<String, dynamic>? notes,
    bool? isCompleted,
    int? durationMinutes,
    String? projectId,
  }) {
    return PomodoroSessionModel(
      id: id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      projectId: projectId ?? this.projectId,
    );
  }
  
  // Calculate actual duration in minutes
  int get actualDurationMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}
