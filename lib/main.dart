import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/sync_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/goals/data/repositories/goal_repository_impl.dart';
import 'features/goals/domain/repositories/goal_repository.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/journal/data/repositories/journal_repository_impl.dart';
import 'features/journal/domain/repositories/journal_repository.dart';
import 'features/knowledge/data/repositories/knowledge_repository_impl.dart';
import 'features/knowledge/domain/repositories/knowledge_repository.dart';
import 'features/pomodoro/data/repositories/pomodoro_repository_impl.dart';
import 'features/pomodoro/domain/repositories/pomodoro_repository.dart';
import 'features/projects/data/repositories/project_repository_impl.dart';
import 'features/projects/domain/repositories/project_repository.dart';

final GetIt getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register all adapters for Hive
  _registerHiveAdapters();
  
  // Set up dependency injection
  await _setupDependencyInjection();
  
  runApp(const SecondBrainApp());
}

void _registerHiveAdapters() {
  // Register all Hive adapters here for models
  // These will be implemented in respective model classes
}

Future<void> _setupDependencyInjection() async {
  // Core services
  getIt.registerSingleton<FirebaseService>(FirebaseService());
  getIt.registerSingleton<AuthService>(AuthService(getIt<FirebaseService>()));
  getIt.registerSingleton<LocalStorageService>(await LocalStorageService.init());
  getIt.registerSingleton<SyncService>(SyncService(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<AuthService>(),
  ));
  
  // Repositories
  getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
  ));
  
  getIt.registerSingleton<HomeRepository>(HomeRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<ProjectRepository>(ProjectRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<PomodoroRepository>(PomodoroRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<DashboardRepository>(DashboardRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<JournalRepository>(JournalRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<KnowledgeRepository>(KnowledgeRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
  
  getIt.registerSingleton<GoalRepository>(GoalRepositoryImpl(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<SyncService>(),
  ));
}
