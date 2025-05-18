import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../domain/repositories/home_repository.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../../goals/domain/repositories/goal_repository.dart';

// Events
@immutable
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshHomeDataEvent extends HomeEvent {}

// States
@immutable
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<String, dynamic> dailyFocus;
  final List<Map<String, dynamic>> suggestedTasks;
  final List<Map<String, dynamic>> topGoals;
  final bool isOffline;
  
  HomeLoaded({
    required this.dailyFocus,
    required this.suggestedTasks,
    required this.topGoals,
    this.isOffline = false,
  });
  
  @override
  List<Object?> get props => [dailyFocus, suggestedTasks, topGoals, isOffline];
  
  HomeLoaded copyWith({
    Map<String, dynamic>? dailyFocus,
    List<Map<String, dynamic>>? suggestedTasks,
    List<Map<String, dynamic>>? topGoals,
    bool? isOffline,
  }) {
    return HomeLoaded(
      dailyFocus: dailyFocus ?? this.dailyFocus,
      suggestedTasks: suggestedTasks ?? this.suggestedTasks,
      topGoals: topGoals ?? this.topGoals,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  
  HomeError(this.message);
  
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
      
      final dailyFocus = await homeRepository.getDailyFocus();
      final suggestedTasks = await homeRepository.getSuggestedTasks();
      final topGoals = await homeRepository.getTopGoals();
      
      // Expand task data with project information
      final expandedTasks = await _expandTasksWithProjects(suggestedTasks);
      
      emit(HomeLoaded(
        dailyFocus: dailyFocus,
        suggestedTasks: expandedTasks,
        topGoals: topGoals,
      ));
    } catch (e) {
      emit(HomeError('Failed to load home data: $e'));
    }
  }
  
  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final currentState = state;
      
      if (currentState is HomeLoaded) {
        emit(currentState.copyWith(isOffline: false));
      } else {
        emit(HomeLoading());
      }
      
      final dailyFocus = await homeRepository.getDailyFocus();
      final suggestedTasks = await homeRepository.getSuggestedTasks();
      final topGoals = await homeRepository.getTopGoals();
      
      // Expand task data with project information
      final expandedTasks = await _expandTasksWithProjects(suggestedTasks);
      
      emit(HomeLoaded(
        dailyFocus: dailyFocus,
        suggestedTasks: expandedTasks,
        topGoals: topGoals,
      ));
    } catch (e) {
      final currentState = state;
      if (currentState is HomeLoaded) {
        emit(currentState.copyWith(isOffline: true));
      } else {
        emit(HomeError('Failed to refresh home data: $e'));
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> _expandTasksWithProjects(List<Map<String, dynamic>> tasks) async {
    final result = <Map<String, dynamic>>[];
    
    for (final task in tasks) {
      final projectId = task['projectId'] as String?;
      
      if (projectId != null) {
        try {
          final project = await projectRepository.getProject(projectId);
          
          if (project != null) {
            result.add({
              ...task,
              'projectName': project['name'],
              'projectColor': project['color'],
            });
          } else {
            result.add(task);
          }
        } catch (e) {
          // If project can't be loaded, still include the task
          result.add(task);
        }
      } else {
        result.add(task);
      }
    }
    
    return result;
  }
}
