import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'auth_service.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';
import '../constants/app_constants.dart';

/// Service for handling data synchronization between local storage and Firebase
class SyncService {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;
  final AuthService _authService;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  
  // Stream to listen for sync status changes
  Stream<bool> get syncStatusStream => _syncStatusController.stream;
  
  // Current sync status
  bool get isSyncing => _isSyncing;
  
  SyncService(
    this._firebaseService,
    this._localStorageService,
    this._authService,
  ) {
    // Start periodic sync
    _startPeriodicSync();
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // We got connectivity, try to sync
        sync();
      }
    });
  }
  
  // Start periodic synchronization
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: AppConstants.syncInterval),
      (_) => sync(),
    );
  }
  
  // Stop periodic synchronization
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  // Manual synchronization
  Future<bool> sync() async {
    // Check if authenticated
    if (!_authService.isAuthenticated) {
      return false;
    }
    
    // Check if already syncing
    if (_isSyncing) {
      return false;
    }
    
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    try {
      _isSyncing = true;
      _syncStatusController.add(true);
      
      // Sync from local to remote
      await _syncLocalToRemote();
      
      // Sync from remote to local
      await _syncRemoteToLocal();
      
      return true;
    } catch (e) {
      print('Sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }
  
  // Sync local changes to remote
  Future<void> _syncLocalToRemote() async {
    // Handle unsynced items
    final unsyncedItems = _localStorageService.getUnsyncedItems();
    for (final item in unsyncedItems) {
      try {
        final boxName = item['boxName'] as String;
        final id = item['id'] as String;
        final data = item['data'] as Map<String, dynamic>;
        
        // Map box name to collection name
        final collectionName = _mapBoxToCollection(boxName);
        
        // Update or create document
        await _firebaseService.setUserDocument(
          collectionName,
          id,
          {...data, 'lastSynced': DateTime.now().toIso8601String()},
        );
        
        // Mark as synced
        await _localStorageService.markItemSynced(boxName, id);
      } catch (e) {
        print('Error syncing item ${item['id']}: $e');
      }
    }
    
    // Handle deleted items
    final deletedItems = _localStorageService.getDeletedItems();
    for (final item in deletedItems) {
      try {
        final boxName = item['boxName'] as String;
        final id = item['id'] as String;
        
        // Map box name to collection name
        final collectionName = _mapBoxToCollection(boxName);
        
        // Delete document
        await _firebaseService.deleteUserDocument(collectionName, id);
        
        // Mark as synced
        await _localStorageService.markItemSynced(boxName, id);
      } catch (e) {
        print('Error deleting item ${item['id']}: $e');
      }
    }
  }
  
  // Sync remote changes to local
  Future<void> _syncRemoteToLocal() async {
    // Get all collections
    final collections = [
      AppConstants.projectsCollection,
      AppConstants.tasksCollection,
      AppConstants.pomodoroSessionsCollection,
      AppConstants.journalEntriesCollection,
      AppConstants.habitsCollection,
      AppConstants.principlesCollection,
      AppConstants.flashcardsCollection,
      AppConstants.goalsCollection,
    ];
    
    for (final collection in collections) {
      try {
        // Get all documents from the collection
        final snapshot = await _firebaseService.getAllFromUserCollection(collection);
        
        // Map collection name to box name
        final boxName = _mapCollectionToBox(collection);
        
        // Update local storage
        for (final doc in snapshot.docs) {
          final id = doc.id;
          final data = doc.data() as Map<String, dynamic>;
          
          // Save to local storage without marking for sync
          await _localStorageService.saveItem(boxName, id, data);
          await _localStorageService.markItemSynced(boxName, id);
        }
      } catch (e) {
        print('Error syncing collection $collection: $e');
      }
    }
  }
  
  // Map box name to collection name
  String _mapBoxToCollection(String boxName) {
    switch (boxName) {
      case AppConstants.projectsBox:
        return AppConstants.projectsCollection;
      case AppConstants.tasksBox:
        return AppConstants.tasksCollection;
      case AppConstants.pomodoroSessionsBox:
        return AppConstants.pomodoroSessionsCollection;
      case AppConstants.journalEntriesBox:
        return AppConstants.journalEntriesCollection;
      case AppConstants.habitsBox:
        return AppConstants.habitsCollection;
      case AppConstants.principlesBox:
        return AppConstants.principlesCollection;
      case AppConstants.flashcardsBox:
        return AppConstants.flashcardsCollection;
      case AppConstants.goalsBox:
        return AppConstants.goalsCollection;
      default:
        throw Exception('Box $boxName has no mapped collection');
    }
  }
  
  // Map collection name to box name
  String _mapCollectionToBox(String collectionName) {
    switch (collectionName) {
      case AppConstants.projectsCollection:
        return AppConstants.projectsBox;
      case AppConstants.tasksCollection:
        return AppConstants.tasksBox;
      case AppConstants.pomodoroSessionsCollection:
        return AppConstants.pomodoroSessionsBox;
      case AppConstants.journalEntriesCollection:
        return AppConstants.journalEntriesBox;
      case AppConstants.habitsCollection:
        return AppConstants.habitsBox;
      case AppConstants.principlesCollection:
        return AppConstants.principlesBox;
      case AppConstants.flashcardsCollection:
        return AppConstants.flashcardsBox;
      case AppConstants.goalsCollection:
        return AppConstants.goalsBox;
      default:
        throw Exception('Collection $collectionName has no mapped box');
    }
  }
  
  // Cleanup when service is no longer needed
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}
