import 'package:get_it/get_it.dart';
import '../../features/goals/data/repositories/goal_repository_impl.dart';
import '../../features/goals/domain/repositories/goal_repository.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  // Repositories
  getIt.registerLazySingleton<GoalRepository>(
    () => GoalRepositoryImpl(),
  );

  // ... existing code ...
} 