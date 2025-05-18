import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../projects/data/repositories/project_repository_impl.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../models/pomodoro_session_model.dart';

class PomodoroRepositoryImpl implements PomodoroRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  final ProjectRepositoryImpl _projectRepository;
  final Uuid _uuid = const Uuid();
  
  PomodoroRepositoryImpl(
    this._firebaseService,
    this._localStorageService,
    this._syncService,
    this._projectRepository,
  );
  
  @override
  Future<List<Map<String, dynamic>>> getPomodoroSessions({String? taskId}) async {
    try {
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      if (taskId != null) {
        return sessions.where((session) => session['taskId'] == taskId).toList();
      }
      
      return sessions;
    } catch (e) {
      print('Error getting pomodoro sessions: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getPomodoroSession(String sessionId) async {
    try {
      return _localStorageService.getItem(AppConstants.pomodoroSessionsBox, sessionId);
    } catch (e) {
      print('Error getting pomodoro session: $e');
      return null;
    }
  }
  
  @override
  Future<String> startPomodoroSession({
    required String taskId, 
    required int durationMinutes,
    String? projectId,
  }) async {
    try {
      final now = DateTime.now();
      final sessionId = _uuid.v4();
      
      // If no project ID provided, try to get it from the task
      if (projectId == null) {
        final task = await _projectRepository.getTask(taskId);
        if (task != null) {
          projectId = task['projectId'] as String?;
        }
      }
      
      // Create pomodoro session model
      final sessionModel = PomodoroSessionModel(
        id: sessionId,
        taskId: taskId,
        startTime: now,
        endTime: now.add(Duration(minutes: durationMinutes)),
        isCompleted: false,
        durationMinutes: durationMinutes,
        projectId: projectId,
      );
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.pomodoroSessionsBox,
        sessionId,
        sessionModel.toJson(),
      );
      
      // Trigger sync
      _syncService.sync();
      
      return sessionId;
    } catch (e) {
      print('Error starting pomodoro session: $e');
      throw Exception('Failed to start pomodoro session: $e');
    }
  }
  
  @override
  Future<void> completePomodoroSession({
    required String sessionId, 
    double? rating,
    Map<String, dynamic>? notes,
  }) async {
    try {
      // Get current session data
      final sessionData = await getPomodoroSession(sessionId);
      if (sessionData == null) {
        throw Exception('Pomodoro session not found');
      }
      
      // Update session
      final now = DateTime.now();
      final updates = {
        'endTime': now.toIso8601String(),
        'isCompleted': true,
        'rating': rating,
        'notes': notes,
      };
      
      // Calculate actual duration
      final startTime = DateTime.parse(sessionData['startTime'] as String);
      final actualDurationMinutes = now.difference(startTime).inMinutes;
      
      // Update duration if it's different from planned
      if (actualDurationMinutes != sessionData['durationMinutes']) {
        updates['durationMinutes'] = actualDurationMinutes;
      }
      
      final updatedData = {
        ...sessionData,
        ...updates,
      };
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.pomodoroSessionsBox,
        sessionId,
        updatedData,
      );
      
      // Update task with completed pomodoro
      final taskId = sessionData['taskId'] as String;
      final task = await _projectRepository.getTask(taskId);
      if (task != null) {
        // Add session ID to task's pomodoro sessions list
        final pomodoroSessionIds = task['pomodoroSessionIds'] != null
            ? List<String>.from(task['pomodoroSessionIds'] as List)
            : <String>[];
        
        if (!pomodoroSessionIds.contains(sessionId)) {
          pomodoroSessionIds.add(sessionId);
          
          // Increment completed pomodoros count
          final completedPomodoros = (task['completedPomodoros'] as int?) ?? 0;
          
          await _projectRepository.updateTask(
            taskId,
            {
              'pomodoroSessionIds': pomodoroSessionIds,
              'completedPomodoros': completedPomodoros + 1,
              'updatedAt': now.toIso8601String(),
            },
          );
        }
      }
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error completing pomodoro session: $e');
      throw Exception('Failed to complete pomodoro session: $e');
    }
  }
  
  @override
  Future<void> cancelPomodoroSession(String sessionId) async {
    try {
      // Delete session from local storage
      await _localStorageService.deleteItem(AppConstants.pomodoroSessionsBox, sessionId);
      
      // Trigger sync
      _syncService.sync();
    } catch (e) {
      print('Error canceling pomodoro session: $e');
      throw Exception('Failed to cancel pomodoro session: $e');
    }
  }
  
  @override
  Future<int> getTotalPomodoroMinutesForDay(DateTime date) async {
    try {
      final dayStart = DateTimeUtils.startOfDay(date);
      final dayEnd = DateTimeUtils.endOfDay(date);
      
      // Get all completed sessions
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Filter sessions for the specified day
      final daySessions = sessions.where((session) {
        if (session['isCompleted'] != true) return false;
        
        final endTime = DateTime.parse(session['endTime'] as String);
        return endTime.isAfter(dayStart) && endTime.isBefore(dayEnd);
      }).toList();
      
      // Sum up durations
      int totalMinutes = 0;
      for (final session in daySessions) {
        totalMinutes += session['durationMinutes'] as int;
      }
      
      return totalMinutes;
    } catch (e) {
      print('Error getting total pomodoro minutes for day: $e');
      return 0;
    }
  }
  
  @override
  Future<int> getTotalPomodoroMinutesForWeek(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      // Get all completed sessions
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Filter sessions for the specified week
      final weekSessions = sessions.where((session) {
        if (session['isCompleted'] != true) return false;
        
        final endTime = DateTime.parse(session['endTime'] as String);
        return endTime.isAfter(weekStart) && endTime.isBefore(weekEnd);
      }).toList();
      
      // Sum up durations
      int totalMinutes = 0;
      for (final session in weekSessions) {
        totalMinutes += session['durationMinutes'] as int;
      }
      
      return totalMinutes;
    } catch (e) {
      print('Error getting total pomodoro minutes for week: $e');
      return 0;
    }
  }
  
  @override
  Future<double?> getAverageRatingForDay(DateTime date) async {
    try {
      final dayStart = DateTimeUtils.startOfDay(date);
      final dayEnd = DateTimeUtils.endOfDay(date);
      
      // Get all completed sessions
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Filter sessions for the specified day
      final daySessions = sessions.where((session) {
        if (session['isCompleted'] != true) return false;
        if (session['rating'] == null) return false;
        
        final endTime = DateTime.parse(session['endTime'] as String);
        return endTime.isAfter(dayStart) && endTime.isBefore(dayEnd);
      }).toList();
      
      if (daySessions.isEmpty) return null;
      
      // Calculate average rating
      double totalRating = 0;
      for (final session in daySessions) {
        totalRating += session['rating'] as double;
      }
      
      return totalRating / daySessions.length;
    } catch (e) {
      print('Error getting average rating for day: $e');
      return null;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getPomodoroSessionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get all completed sessions
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Filter sessions for the specified date range
      return sessions.where((session) {
        if (session['isCompleted'] != true) return false;
        
        final endTime = DateTime.parse(session['endTime'] as String);
        return endTime.isAfter(startDate) && endTime.isBefore(endDate);
      }).toList();
    } catch (e) {
      print('Error getting pomodoro sessions for date range: $e');
      return [];
    }
  }
  
  @override
  Future<int> getPomodoroSessionsCountByTask(String taskId) async {
    try {
      // Get sessions for the specified task
      final sessions = await getPomodoroSessions(taskId: taskId);
      
      // Count only completed sessions
      return sessions.where((session) => session['isCompleted'] == true).length;
    } catch (e) {
      print('Error getting pomodoro sessions count by task: $e');
      return 0;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getOngoingPomodoroSession() async {
    try {
      // Get all sessions
      final sessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Find the first incomplete session
      for (final session in sessions) {
        if (session['isCompleted'] != true) {
          return session;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting ongoing pomodoro session: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getPomodoroSettings() async {
    try {
      final settings = _localStorageService.getItem(
        AppConstants.settingsBox,
        'pomodoroSettings',
      );
      
      if (settings != null) {
        return settings;
      }
      
      // Return default settings
      return {
        'pomodoroMinutes': AppConstants.defaultPomodoroMinutes,
        'shortBreakMinutes': AppConstants.defaultShortBreakMinutes,
        'longBreakMinutes': AppConstants.defaultLongBreakMinutes,
        'pomodorosBeforeLongBreak': AppConstants.defaultPomodorosBeforeLongBreak,
        'autoStartNextSession': false,
      };
    } catch (e) {
      print('Error getting pomodoro settings: $e');
      
      // Return default settings
      return {
        'pomodoroMinutes': AppConstants.defaultPomodoroMinutes,
        'shortBreakMinutes': AppConstants.defaultShortBreakMinutes,
        'longBreakMinutes': AppConstants.defaultLongBreakMinutes,
        'pomodorosBeforeLongBreak': AppConstants.defaultPomodorosBeforeLongBreak,
        'autoStartNextSession': false,
      };
    }
  }
  
  @override
  Future<void> savePomodoroSettings(Map<String, dynamic> settings) async {
    try {
      await _localStorageService.saveItem(
        AppConstants.settingsBox,
        'pomodoroSettings',
        settings,
      );
    } catch (e) {
      print('Error saving pomodoro settings: $e');
      throw Exception('Failed to save pomodoro settings: $e');
    }
  }
}
