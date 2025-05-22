import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../../goals/domain/repositories/goal_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshHomeDataEvent extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, dynamic> dailyFocus;
  final List<Map<String, dynamic>> suggestedTasks;
  final List<Map<String, dynamic>> topGoals;

  const HomeLoaded({
    required this.dailyFocus,
    required this.suggestedTasks,
    required this.topGoals,
  });

  @override
  List<Object?> get props => [dailyFocus, suggestedTasks, topGoals];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;
  final ProjectRepository projectRepository;
  final GoalRepository goalRepository;

  HomeBloc({
    required this.homeRepository,
    required this.projectRepository,
    required this.goalRepository,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());
      print('Loading home data...');

      final dailyFocus = await homeRepository.getDailyFocus();
      print('Daily focus loaded: $dailyFocus');

      final suggestedTasks = await homeRepository.getSuggestedTasks();
      print('Suggested tasks loaded: ${suggestedTasks.length} tasks');

      final topGoals = await homeRepository.getTopGoals();
      print('Top goals loaded: ${topGoals.length} goals');

      emit(HomeLoaded(
        dailyFocus: dailyFocus,
        suggestedTasks: suggestedTasks,
        topGoals: topGoals,
      ));
      print('Home data loaded successfully');
    } catch (e) {
      print('Error loading home data: $e');
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is HomeLoaded) {
        emit(HomeLoading());
        print('Refreshing home data...');

        final dailyFocus = await homeRepository.getDailyFocus();
        print('Daily focus refreshed: $dailyFocus');

        final suggestedTasks = await homeRepository.getSuggestedTasks();
        print('Suggested tasks refreshed: ${suggestedTasks.length} tasks');

        final topGoals = await homeRepository.getTopGoals();
        print('Top goals refreshed: ${topGoals.length} goals');

        emit(HomeLoaded(
          dailyFocus: dailyFocus,
          suggestedTasks: suggestedTasks,
          topGoals: topGoals,
        ));
        print('Home data refreshed successfully');
      }
    } catch (e) {
      print('Error refreshing home data: $e');
      emit(HomeError(e.toString()));
    }
  }
}
