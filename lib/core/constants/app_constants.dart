class AppConstants {
  // App Information
  static const String appName = 'Second Brain';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String tasksCollection = 'tasks';
  static const String pomodoroSessionsCollection = 'pomodoroSessions';
  static const String journalEntriesCollection = 'journalEntries';
  static const String habitsCollection = 'habits';
  static const String principlesCollection = 'principles';
  static const String flashcardsCollection = 'flashcards';
  static const String goalsCollection = 'goals';
  
  // Hive Boxes
  static const String userBox = 'userBox';
  static const String projectsBox = 'projectsBox';
  static const String tasksBox = 'tasksBox';
  static const String pomodoroSessionsBox = 'pomodoroSessionsBox';
  static const String journalEntriesBox = 'journalEntriesBox';
  static const String habitsBox = 'habitsBox';
  static const String principlesBox = 'principlesBox';
  static const String flashcardsBox = 'flashcardsBox';
  static const String goalsBox = 'goalsBox';
  static const String syncStatusBox = 'syncStatusBox';
  static const String settingsBox = 'settingsBox';
  
  // Pomodoro Settings
  static const int defaultPomodoroMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultPomodorosBeforeLongBreak = 4;
  
  // Journal Templates
  static const List<String> journalPrompts = [
    'What were your victories today?',
    'What lessons did you learn today?',
    'What mistakes did you make today and how will you improve?',
    'What are you grateful for today?',
    'What is your focus for tomorrow?',
  ];
  
  // Goal Timeframes
  static const String annual = 'Annual';
  static const String quarterly = 'Quarterly';
  static const String monthly = 'Monthly';
  
  // Tags
  static const List<String> defaultTags = [
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Finance',
    'Social',
    'Creative',
  ];
  
  // Rating Descriptions
  static const Map<int, String> ratingDescriptions = {
    1: 'Very Poor',
    2: 'Poor',
    3: 'Average',
    4: 'Good',
    5: 'Excellent',
  };
  
  // Sync intervals in minutes
  static const int syncInterval = 5;
  
  // Greetings based on time of day
  static const Map<String, List<String>> timeBasedGreetings = {
    'morning': [
      'Good morning!',
      'Rise and shine!',
      'Hello, early bird!',
    ],
    'afternoon': [
      'Good afternoon!',
      'Hello there!',
      'Hope your day is going well!',
    ],
    'evening': [
      'Good evening!',
      'Winding down?',
      'How was your day?',
    ],
    'night': [
      'Good night!',
      'Time to reflect on today.',
      'Let\'s review your day.',
    ],
  };
  
  // Success Messages
  static const String projectCreatedSuccess = 'Project created successfully';
  static const String projectUpdatedSuccess = 'Project updated successfully';
  static const String projectDeletedSuccess = 'Project deleted successfully';
  static const String taskCreatedSuccess = 'Task created successfully';
  static const String taskUpdatedSuccess = 'Task updated successfully';
  static const String taskDeletedSuccess = 'Task deleted successfully';
  static const String sessionCompletedSuccess = 'Pomodoro session completed!';
  static const String journalEntrySuccess = 'Journal entry saved successfully';
  static const String principleAddedSuccess = 'Principle added successfully';
  static const String flashcardAddedSuccess = 'Flashcard added successfully';
  static const String goalCreatedSuccess = 'Goal created successfully';
  static const String goalUpdatedSuccess = 'Goal updated successfully';
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Working in offline mode.';
  static const String syncError = 'Sync failed. Will retry later.';
  static const String authError = 'Authentication failed. Please try again.';
  
  // New keys
  static const String userKey = 'user';
  static const String settingsKey = 'settings';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
}
