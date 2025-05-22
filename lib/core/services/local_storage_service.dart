import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import 'package:shared_preferences.dart';

/// Service for managing local storage with Hive database
class LocalStorageService {
  late Box _userBox;
  late Box _projectsBox;
  late Box _tasksBox;
  late Box _pomodoroSessionsBox;
  late Box _journalEntriesBox;
  late Box _habitsBox;
  late Box _principlesBox;
  late Box _flashcardsBox;
  late Box _goalsBox;
  late Box _syncStatusBox;
  late Box _settingsBox;
  final SharedPreferences _prefs;
  
  // Private constructor
  LocalStorageService._(this._prefs);

  // Factory constructor for initialization
  static Future<LocalStorageService> init(SharedPreferences prefs) async {
    final service = LocalStorageService._(prefs);
    
    // Open all Hive boxes
    service._userBox = await Hive.openBox(AppConstants.userBox);
    service._projectsBox = await Hive.openBox(AppConstants.projectsBox);
    service._tasksBox = await Hive.openBox(AppConstants.tasksBox);
    service._pomodoroSessionsBox = await Hive.openBox(AppConstants.pomodoroSessionsBox);
    service._journalEntriesBox = await Hive.openBox(AppConstants.journalEntriesBox);
    service._habitsBox = await Hive.openBox(AppConstants.habitsBox);
    service._principlesBox = await Hive.openBox(AppConstants.principlesBox);
    service._flashcardsBox = await Hive.openBox(AppConstants.flashcardsBox);
    service._goalsBox = await Hive.openBox(AppConstants.goalsBox);
    service._syncStatusBox = await Hive.openBox(AppConstants.syncStatusBox);
    service._settingsBox = await Hive.openBox(AppConstants.settingsBox);
    
    return service;
  }
  
  // User data methods
  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _prefs.setString(AppConstants.userKey, json.encode(userData));
  }
  
  Map<String, dynamic>? getUser() {
    final userJson = _prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    return json.decode(userJson) as Map<String, dynamic>;
  }
  
  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.userKey);
  }
  
  String? getUserId() {
    final user = getUser();
    return user != null ? user['uid'] as String? : null;
  }
  
  // Generic CRUD operations for collections
  Future<void> saveItem(String boxName, String id, Map<String, dynamic> data) async {
    final box = _getBoxByName(boxName);
    await box.put(id, data);
    
    // Mark as not synced
    await markItemForSync(boxName, id);
  }
  
  Map<String, dynamic>? getItem(String boxName, String id) {
    final box = _getBoxByName(boxName);
    final data = box.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  Future<void> deleteItem(String boxName, String id) async {
    final box = _getBoxByName(boxName);
    await box.delete(id);
    
    // Mark deletion for sync
    await _syncStatusBox.put('deleted_${boxName}_$id', true);
  }
  
  List<Map<String, dynamic>> getAllItems(String boxName) {
    final box = _getBoxByName(boxName);
    final List<Map<String, dynamic>> items = [];
    
    for (final key in box.keys) {
      final item = box.get(key);
      if (item != null) {
        items.add(Map<String, dynamic>.from(item));
      }
    }
    
    return items;
  }
  
  // Sync status tracking
  Future<void> markItemForSync(String boxName, String id) async {
    await _syncStatusBox.put('unsynced_${boxName}_$id', DateTime.now().toIso8601String());
  }
  
  Future<void> markItemSynced(String boxName, String id) async {
    await _syncStatusBox.delete('unsynced_${boxName}_$id');
    await _syncStatusBox.delete('deleted_${boxName}_$id');
  }
  
  List<Map<String, dynamic>> getUnsyncedItems() {
    final List<Map<String, dynamic>> unsyncedItems = [];
    
    for (final key in _syncStatusBox.keys) {
      if (key.toString().startsWith('unsynced_')) {
        final parts = key.toString().split('_');
        if (parts.length >= 3) {
          final boxName = parts[1];
          final itemId = parts.sublist(2).join('_'); // Handle IDs with underscores
          
          final item = getItem(boxName, itemId);
          if (item != null) {
            unsyncedItems.add({
              'boxName': boxName,
              'id': itemId,
              'data': item,
              'timestamp': _syncStatusBox.get(key),
            });
          }
        }
      }
    }
    
    return unsyncedItems;
  }
  
  List<Map<String, dynamic>> getDeletedItems() {
    final List<Map<String, dynamic>> deletedItems = [];
    
    for (final key in _syncStatusBox.keys) {
      if (key.toString().startsWith('deleted_')) {
        final parts = key.toString().split('_');
        if (parts.length >= 3) {
          final boxName = parts[1];
          final itemId = parts.sublist(2).join('_'); // Handle IDs with underscores
          
          deletedItems.add({
            'boxName': boxName,
            'id': itemId,
          });
        }
      }
    }
    
    return deletedItems;
  }
  
  // Clear all data (for logout)
  Future<void> clearAllData() async {
    await _prefs.clear();
    await _userBox.clear();
    await _projectsBox.clear();
    await _tasksBox.clear();
    await _pomodoroSessionsBox.clear();
    await _journalEntriesBox.clear();
    await _habitsBox.clear();
    await _principlesBox.clear();
    await _flashcardsBox.clear();
    await _goalsBox.clear();
    await _syncStatusBox.clear();
    // Don't clear settings box to maintain app preferences
  }
  
  // Settings methods
  Map<String, dynamic>? getSettings() {
    final settingsJson = _prefs.getString(AppConstants.settingsKey);
    if (settingsJson == null) return null;
    return json.decode(settingsJson) as Map<String, dynamic>;
  }
  
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(AppConstants.settingsKey, json.encode(settings));
  }
  
  // Theme methods
  String? getThemeMode() {
    return _prefs.getString(AppConstants.themeKey);
  }
  
  Future<void> saveThemeMode(String themeMode) async {
    await _prefs.setString(AppConstants.themeKey, themeMode);
  }
  
  // Language methods
  String? getLanguage() {
    return _prefs.getString(AppConstants.languageKey);
  }
  
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(AppConstants.languageKey, language);
  }
  
  // Helper method to get the right box
  Box _getBoxByName(String boxName) {
    switch (boxName) {
      case AppConstants.userBox:
        return _userBox;
      case AppConstants.projectsBox:
        return _projectsBox;
      case AppConstants.tasksBox:
        return _tasksBox;
      case AppConstants.pomodoroSessionsBox:
        return _pomodoroSessionsBox;
      case AppConstants.journalEntriesBox:
        return _journalEntriesBox;
      case AppConstants.habitsBox:
        return _habitsBox;
      case AppConstants.principlesBox:
        return _principlesBox;
      case AppConstants.flashcardsBox:
        return _flashcardsBox;
      case AppConstants.goalsBox:
        return _goalsBox;
      case AppConstants.syncStatusBox:
        return _syncStatusBox;
      case AppConstants.settingsBox:
        return _settingsBox;
      default:
        throw Exception('Box $boxName not found');
    }
  }
}
