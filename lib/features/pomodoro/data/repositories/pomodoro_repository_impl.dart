import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  PomodoroRepositoryImpl(
    this._firebaseService,
    this._localStorageService,
    this._syncService,
    this._projectRepository,
  );
  
  String get _userId => _auth.currentUser?.uid ?? '';
  
  @override
  Future<List<Map<String, dynamic>>> getPomodoroSessions({String? taskId}) async {
    try {
      if (_userId.isEmpty) return [];

      Query query = _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions');

      if (taskId != null) {
        query = query.where('taskId', isEqualTo: taskId);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting pomodoro sessions: $e');
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getPomodoroSession(String sessionId) async {
    try {
      if (_userId.isEmpty) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .doc(sessionId)
          .get();

      return doc.data();
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
    print('DEBUG: ENTERED startPomodoroSession');
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      final now = DateTime.now();
      final sessionId = _uuid.v4();
      print('DEBUG: startPomodoroSession _userId=$_userId, sessionId=$sessionId');
      print('DEBUG: Firestore instance: $_firestore');
      print('DEBUG: Auth instance: $_auth');
      print('DEBUG: Current user: ${_auth.currentUser?.uid}');
      
      // If no project ID provided, try to get it from the task
      if (projectId == null) {
        final task = await _projectRepository.getTask(taskId);
        if (task != null) {
          projectId = task['projectId'] as String?;
          print('DEBUG: Got projectId from task: $projectId');
        }
      }
      
      // Fetch task and project details for session metadata
      String taskTitle = 'Unknown Task';
      String projectTitle = 'Unknown Project';
      String projectColor = '#2196F3';
      final task = await _projectRepository.getTask(taskId);
      if (task != null) {
        taskTitle = task['title'] as String? ?? taskTitle;
        if (task['projectId'] != null) {
          final project = await _projectRepository.getProject(task['projectId'] as String);
          if (project != null) {
            projectTitle = project['name'] as String? ?? projectTitle;
            projectColor = project['color'] as String? ?? projectColor;
          }
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
      final sessionData = sessionModel.toFirebase();
      sessionData['taskTitle'] = taskTitle;
      sessionData['projectTitle'] = projectTitle;
      sessionData['projectColor'] = projectColor;
      
      // REMOVE TEST WRITES
      // Only keep the real session write
      print('DEBUG: Writing session to users/$_userId/pomodoroSessions with data: $sessionData');
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .doc(sessionId)
          .set(sessionData)
          .then((_) => print('DEBUG: Wrote session to users/$_userId/pomodoroSessions/$sessionId'))
          .catchError((e) => print('ERROR: Failed to write session: $e'));

      // Dual write: legacy subcollection under task
      if (projectId != null) {
        final legacyPath = 'users/$_userId/projects/$projectId/tasks/$taskId/sessions/$sessionId';
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('projects')
            .doc(projectId)
            .collection('tasks')
            .doc(taskId)
            .collection('sessions')
            .doc(sessionId)
            .set(sessionData)
            .then((_) => print('DEBUG: Wrote session to $legacyPath'))
            .catchError((e) => print('ERROR: Failed to write session to $legacyPath: $e'));
      }
      return sessionId;
    } catch (e, stack) {
      print('ERROR in startPomodoroSession: $e\n$stack');
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
      if (_userId.isEmpty) throw Exception('User not authenticated');

      // Get current session data
      final sessionData = await getPomodoroSession(sessionId);
      if (sessionData == null) {
        throw Exception('Pomodoro session not found');
      }
      
      // Update session
      final now = DateTime.now();
      final updates = {
        'endTime': now,
        'isCompleted': true,
        'rating': rating,
        'notes': notes,
      };
      
      // Calculate actual duration
      final startTime = (sessionData['startTime'] as Timestamp).toDate();
      final actualDurationMinutes = now.difference(startTime).inMinutes;
      
      // Update duration if it's different from planned
      if (actualDurationMinutes != sessionData['durationMinutes']) {
        updates['durationMinutes'] = actualDurationMinutes;
      }
      
      // Update in Firestore (flat collection)
      final flatPath = 'users/$_userId/pomodoroSessions/$sessionId';
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .doc(sessionId)
          .update(updates);
      print('DEBUG: Updated session in $flatPath');
      // Update in Firestore (legacy subcollection)
      final taskId = sessionData['taskId'] as String;
      final projectId = sessionData['projectId'] as String?;
      if (projectId != null) {
        final legacyPath = 'users/$_userId/projects/$projectId/tasks/$taskId/sessions/$sessionId';
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('projects')
            .doc(projectId)
            .collection('tasks')
            .doc(taskId)
            .collection('sessions')
            .doc(sessionId)
            .update(updates);
        print('DEBUG: Updated session in $legacyPath');
      }
      // Update task with completed pomodoro
      final task = await _projectRepository.getTask(taskId);
      if (task != null) {
        // Add session ID to task's pomodoro sessions list
        final pomodoroSessionIds = (task['pomodoroSessionIds'] as List<dynamic>?)?.cast<String>() ?? [];
        
        if (!pomodoroSessionIds.contains(sessionId)) {
          await _projectRepository.updateTask(
            taskId,
            {
              'pomodoroSessionIds': [...pomodoroSessionIds, sessionId],
              'completedPomodoros': (task['completedPomodoros'] as int? ?? 0) + 1,
              'updatedAt': now,
            },
          );
          print('DEBUG: Updated task $taskId with new session $sessionId');
        }
      }
    } catch (e, stack) {
      print('ERROR in completePomodoroSession: $e\n$stack');
      throw Exception('Failed to complete pomodoro session: $e');
    }
  }
  
  @override
  Future<void> cancelPomodoroSession(String sessionId) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      // Delete session from Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .doc(sessionId)
          .delete();
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
      final sessions = await getPomodoroSessions();
      
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
      final sessions = await getPomodoroSessions();
      
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
      final sessions = await getPomodoroSessions();
      
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
      if (_userId.isEmpty) return [];

      // NOTE: If you filter/sort on multiple fields, Firestore may require a composite index.
      // This query fetches ALL sessions in the date range, regardless of isCompleted.
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .where('endTime', isGreaterThanOrEqualTo: startDate)
          .where('endTime', isLessThanOrEqualTo: endDate)
          .orderBy('endTime')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting pomodoro sessions for date range: $e');
      return [];
    }
  }
  
  @override
  Future<int> getPomodoroSessionsCountByTask(String taskId) async {
    try {
      if (_userId.isEmpty) return 0;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .where('taskId', isEqualTo: taskId)
          .where('isCompleted', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting pomodoro sessions count by task: $e');
      return 0;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getOngoingPomodoroSession() async {
    try {
      if (_userId.isEmpty) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('pomodoroSessions')
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first.data();
    } catch (e) {
      print('Error getting ongoing pomodoro session: $e');
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getPomodoroSettings() async {
    try {
      if (_userId.isEmpty) return {};

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('pomodoro')
          .get();

      return doc.data() ?? {};
    } catch (e) {
      print('Error getting pomodoro settings: $e');
      return {};
    }
  }
  
  @override
  Future<void> savePomodoroSettings(Map<String, dynamic> settings) async {
    try {
      if (_userId.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('pomodoro')
          .set(settings);
    } catch (e) {
      print('Error saving pomodoro settings: $e');
      throw Exception('Failed to save pomodoro settings: $e');
    }
  }
}
