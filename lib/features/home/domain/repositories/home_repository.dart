/// Repository interface for home screen functionality
abstract class HomeRepository {
  /// Get the daily focus data for the current day
  Future<Map<String, dynamic>> getDailyFocus();
  
  /// Get suggested tasks for today
  Future<List<Map<String, dynamic>>> getSuggestedTasks();
  
  /// Get top goals for the user
  Future<List<Map<String, dynamic>>> getTopGoals();
  
  /// Calculate age in days from birth date if available
  Future<int?> getAgeInDays();
  
  /// Get appropriate greeting based on time of day
  String getGreeting();
  
  /// Get yesterday's average rating if available
  Future<double?> getYesterdayAverageRating();
  
  /// Get a motivational quote
  Future<String?> getMotivationalQuote();
}
