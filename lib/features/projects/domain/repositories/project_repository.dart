/// Repository interface for project and task management
abstract class ProjectRepository {
  // Project methods
  Future<List<Map<String, dynamic>>> getProjects({bool includeArchived = false});
  
  Future<Map<String, dynamic>?> getProject(String projectId);
  
  Future<String> createProject(Map<String, dynamic> projectData);
  
  Future<void> updateProject(String projectId, Map<String, dynamic> updates);
  
  Future<void> deleteProject(String projectId);
  
  Future<void> archiveProject(String projectId);
  
  // Task methods
  Future<List<Map<String, dynamic>>> getTasks({String? projectId, bool includeCompleted = false});
  
  Future<Map<String, dynamic>?> getTask(String taskId);
  
  Future<String> createTask(Map<String, dynamic> taskData);
  
  Future<void> updateTask(String taskId, Map<String, dynamic> updates);
  
  Future<void> deleteTask(String taskId);
  
  Future<void> completeTask(String taskId);
  
  Future<void> moveTaskToProject(String taskId, String newProjectId);
  
  // Task tag methods
  Future<List<String>> getAvailableTags();
  
  Future<void> saveAvailableTags(List<String> tags);
  
  // Utility methods
  Future<int> getTasksCountForProject(String projectId, {bool onlyIncomplete = true});
  
  Future<List<Map<String, dynamic>>> getTasksWithUpcomingDeadlines({int daysAhead = 7});
  
  Future<List<Map<String, dynamic>>> getRecentTasks({int limit = 10});
}
