import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String projectId;
  final String title;
  final bool completed;
  final int estimatedPomodoros;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int completedPomodoros;
  final int elapsedTime;

  // Pomodoro Timer Settings
  final int? workDuration; // in minutes
  final int? shortBreakDuration; // in minutes
  final int? longBreakDuration; // in minutes
  final int? pomodorosUntilLongBreak;
  final bool? autoStartBreaks;
  final bool? autoStartPomodoros;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.completed = false,
    this.estimatedPomodoros = 0,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.completedPomodoros = 0,
    this.elapsedTime = 0,
    // Pomodoro Timer Settings
    this.workDuration,
    this.shortBreakDuration,
    this.longBreakDuration,
    this.pomodorosUntilLongBreak,
    this.autoStartBreaks,
    this.autoStartPomodoros,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      completed: data['completed'] ?? false,
      estimatedPomodoros: data['estimatedPomodoros'] ?? 0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedPomodoros: data['completedPomodoros'] ?? 0,
      elapsedTime: data['elapsedTime'] ?? 0,
      // Pomodoro Timer Settings
      workDuration: data['workDuration'],
      shortBreakDuration: data['shortBreakDuration'],
      longBreakDuration: data['longBreakDuration'],
      pomodorosUntilLongBreak: data['pomodorosUntilLongBreak'],
      autoStartBreaks: data['autoStartBreaks'],
      autoStartPomodoros: data['autoStartPomodoros'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'completed': completed,
      'estimatedPomodoros': estimatedPomodoros,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedPomodoros': completedPomodoros,
      'elapsedTime': elapsedTime,
      // Pomodoro Timer Settings
      'workDuration': workDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'pomodorosUntilLongBreak': pomodorosUntilLongBreak,
      'autoStartBreaks': autoStartBreaks,
      'autoStartPomodoros': autoStartPomodoros,
    };
  }

  Task copyWith({
    String? id,
    String? projectId,
    String? title,
    bool? completed,
    int? estimatedPomodoros,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    int? completedPomodoros,
    int? elapsedTime,
    // Pomodoro Timer Settings
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? pomodorosUntilLongBreak,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      // Pomodoro Timer Settings
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      pomodorosUntilLongBreak: pomodorosUntilLongBreak ?? this.pomodorosUntilLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
    );
  }
} 