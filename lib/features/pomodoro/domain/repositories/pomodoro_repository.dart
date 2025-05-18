/// Repository interface for pomodoro session management
abstract class PomodoroRepository {
  // Get all pomodoro sessions
  Future<List<Map<String, dynamic>>> getPomodoroSessions({String? taskId});
  
  // Get specific pomodoro session by ID
  Future<Map<String, dynamic>?> getPomodoroSession(String sessionId);
  
  // Start a new pomodoro session
  Future<String> startPomodoroSession({
    required String taskId, 
    required int durationMinutes,
    String? projectId,
  });
  
  // Complete a pomodoro session
  Future<void> completePomodoroSession({
    required String sessionId, 
    double? rating,
    Map<String, dynamic>? notes,
  });
  
  // Cancel an ongoing pomodoro session
  Future<void> cancelPomodoroSession(String sessionId);
  
  // Get total pomodoro time for a specific day
  Future<int> getTotalPomodoroMinutesForDay(DateTime date);
  
  // Get total pomodoro time for a specific week
  Future<int> getTotalPomodoroMinutesForWeek(DateTime weekStart);
  
  // Get average rating for pomodoro sessions on a specific day
  Future<double?> getAverageRatingForDay(DateTime date);
  
  // Get pomodoro sessions for a date range
  Future<List<Map<String, dynamic>>> getPomodoroSessionsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  // Get pomodoro sessions count by task ID
  Future<int> getPomodoroSessionsCountByTask(String taskId);
  
  // Get ongoing pomodoro session if exists
  Future<Map<String, dynamic>?> getOngoingPomodoroSession();
  
  // Get default pomodoro settings
  Future<Map<String, dynamic>> getPomodoroSettings();
  
  // Save pomodoro settings
  Future<void> savePomodoroSettings(Map<String, dynamic> settings);
}
