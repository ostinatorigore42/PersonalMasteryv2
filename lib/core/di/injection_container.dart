import 'package:get_it/get_it.dart';
import '../../features/pomodoro/data/repositories/pomodoro_repository_impl.dart';
import '../../features/pomodoro/domain/repositories/pomodoro_repository.dart';
import '../../features/projects/data/repositories/project_repository_impl.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/auth_service.dart';
// import '../../features/goals/data/repositories/goal_repository_impl.dart';
// import '../../features/goals/domain/repositories/goal_repository.dart';
// import '../../features/journal/data/repositories/journal_repository_impl.dart';
// import '../../features/journal/domain/repositories/journal_repository.dart';
// import '../../features/knowledge/data/repositories/knowledge_repository_impl.dart';
// import '../../features/knowledge/domain/repositories/knowledge_repository.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies(LocalStorageService localStorageService) {
  // Services
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService.instance);
  getIt.registerLazySingleton<LocalStorageService>(() => localStorageService);
  getIt.registerLazySingleton<AuthService>(() => AuthService(getIt<FirebaseService>()));
  getIt.registerLazySingleton<SyncService>(() => SyncService(
    getIt<FirebaseService>(),
    getIt<LocalStorageService>(),
    getIt<AuthService>(),
  ));

  // Repositories
  // getIt.registerLazySingleton<GoalRepository>(
  //   () => GoalRepositoryImpl(),
  // );
  // getIt.registerLazySingleton<JournalRepository>(
  //   () => JournalRepositoryImpl(),
  // );
  // getIt.registerLazySingleton<KnowledgeRepository>(
  //   () => KnowledgeRepositoryImpl(),
  // );
  getIt.registerLazySingleton<ProjectRepositoryImpl>(
    () => ProjectRepositoryImpl(
      getIt<FirebaseService>(),
      getIt<LocalStorageService>(),
      getIt<SyncService>(),
    ),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => getIt<ProjectRepositoryImpl>(),
  );
  getIt.registerLazySingleton<PomodoroRepository>(
    () => PomodoroRepositoryImpl(
      getIt<FirebaseService>(),
      getIt<LocalStorageService>(),
      getIt<SyncService>(),
      getIt<ProjectRepositoryImpl>(),
    ),
  );

  // ... existing code ...
} 