import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../pomodoro/data/models/pomodoro_session_model.dart';
import '../../../projects/data/models/task_model.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/daily_focus_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;
  final SyncService _syncService;
  
  HomeRepositoryImpl(
    this._firebaseService,
    this._localStorageService,
    this._syncService,
  );
  
  @override
  Future<Map<String, dynamic>> getDailyFocus() async {
    try {
      // Get today's date
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Check if daily focus exists in local storage
      final dailyFocusData = _localStorageService.getItem(
        AppConstants.userBox, 
        'daily_focus_$dateStr',
      );
      
      if (dailyFocusData != null) {
        return dailyFocusData;
      }
      
      // If not in local storage, create a new daily focus
      final ageInDays = await getAgeInDays();
      final greeting = getGreeting();
      final topGoals = await getTopGoals();
      final suggestedTasks = await getSuggestedTasks();
      final yesterdayAverageRating = await getYesterdayAverageRating();
      final motivationalQuote = await getMotivationalQuote();
      
      final topGoalIds = topGoals.map((g) => g['id'] as String).toList();
      final suggestedTaskIds = suggestedTasks.map((t) => t['id'] as String).toList();
      
      final dailyFocus = DailyFocusModel(
        date: today,
        greeting: greeting,
        ageInDays: ageInDays ?? 0,
        topGoalIds: topGoalIds,
        suggestedTaskIds: suggestedTaskIds,
        yesterdayAverageRating: yesterdayAverageRating,
        motivationalQuotes: motivationalQuote != null ? [motivationalQuote] : null,
      );
      
      // Save to local storage
      await _localStorageService.saveItem(
        AppConstants.userBox,
        'daily_focus_$dateStr',
        dailyFocus.toJson(),
      );
      
      // Convert model to map
      return dailyFocus.toJson();
    } catch (e) {
      print('Error getting daily focus: $e');
      
      // Return a basic daily focus if there's an error
      return {
        'date': DateTime.now().toIso8601String(),
        'greeting': getGreeting(),
        'ageInDays': 0,
        'topGoalIds': <String>[],
        'suggestedTaskIds': <String>[],
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getSuggestedTasks() async {
    try {
      final userId = _firebaseService.auth.currentUser?.uid;
      print('Fetching tasks for user: $userId');
      
      if (userId == null) {
        print('No user ID found, returning empty list');
        return [];
      }

      // Get tasks from Firestore
      final tasksSnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .limit(5)
          .get();

      print('Found ${tasksSnapshot.docs.length} tasks');

      final tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Save to local storage for offline access
      for (final task in tasks) {
        await _localStorageService.saveItem(
          AppConstants.tasksBox,
          task['id'] as String,
          task,
        );
      }

      return tasks;
    } catch (e) {
      print('Error getting suggested tasks: $e');
      // Fallback to local storage
      final localTasks = _localStorageService.getAllItems(AppConstants.tasksBox);
      print('Falling back to ${localTasks.length} local tasks');
      return localTasks;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTopGoals() async {
    try {
      final userId = _firebaseService.auth.currentUser?.uid;
      print('Fetching goals for user: $userId');
      
      if (userId == null) {
        print('No user ID found, returning empty list');
        return [];
      }

      // Get goals from Firestore
      final goalsSnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .where('isCompleted', isEqualTo: false)
          .orderBy('priority')
          .orderBy('deadline')
          .limit(3)
          .get();

      print('Found ${goalsSnapshot.docs.length} goals');

      final goals = goalsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Save to local storage for offline access
      for (final goal in goals) {
        await _localStorageService.saveItem(
          AppConstants.goalsBox,
          goal['id'] as String,
          goal,
        );
      }

      return goals;
    } catch (e) {
      print('Error getting top goals: $e');
      // Fallback to local storage
      final localGoals = _localStorageService.getAllItems(AppConstants.goalsBox);
      print('Falling back to ${localGoals.length} local goals');
      return localGoals;
    }
  }
  
  @override
  Future<int?> getAgeInDays() async {
    try {
      // Get user data from local storage
      final userData = _localStorageService.getUser();
      if (userData == null) return null;
      
      final user = UserModel.fromJson(userData);
      return user.ageInDays;
    } catch (e) {
      print('Error getting age in days: $e');
      return null;
    }
  }
  
  @override
  String getGreeting() {
    return DateTimeUtils.getGreeting();
  }
  
  @override
  Future<double?> getYesterdayAverageRating() async {
    try {
      // Get yesterday's date
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final yesterdayStart = DateTimeUtils.startOfDay(yesterday);
      final yesterdayEnd = DateTimeUtils.endOfDay(yesterday);
      
      // Get all pomodoro sessions
      final allSessions = _localStorageService.getAllItems(AppConstants.pomodoroSessionsBox);
      
      // Filter sessions from yesterday with ratings
      final yesterdaySessions = allSessions.where((session) {
        if (session['rating'] == null) return false;
        
        final endTime = DateTime.parse(session['endTime'] as String);
        return endTime.isAfter(yesterdayStart) && endTime.isBefore(yesterdayEnd);
      }).toList();
      
      if (yesterdaySessions.isEmpty) return null;
      
      // Calculate average rating
      double total = 0;
      for (final session in yesterdaySessions) {
        total += session['rating'] as double;
      }
      
      return total / yesterdaySessions.length;
    } catch (e) {
      print('Error getting yesterday average rating: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getMotivationalQuote() async {
    // List of motivational quotes
    const quotes = [
      "The only way to do great work is to love what you do.",
      "Success is not final, failure is not fatal: It is the courage to continue that counts.",
      "Believe you can and you're halfway there.",
      "The future belongs to those who believe in the beauty of their dreams.",
      "Don't watch the clock; do what it does. Keep going.",
      "The best way to predict the future is to create it.",
      "Small daily improvements are the key to staggering long-term results.",
      "The only limit to our realization of tomorrow is our doubts of today.",
      "The harder you work for something, the greater you'll feel when you achieve it.",
      "Your time is limited, don't waste it living someone else's life.",
    ];
    
    // Return a random quote
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
}
