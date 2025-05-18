import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
@immutable
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;
  final DateTime? birthDate;
  
  AuthRegisterEvent({
    required this.email,
    required this.password,
    this.displayName,
    this.birthDate,
  });
  
  @override
  List<Object?> get props => [email, password, displayName, birthDate];
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  
  AuthLoginEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthResetPasswordEvent extends AuthEvent {
  final String email;
  
  AuthResetPasswordEvent({required this.email});
  
  @override
  List<Object?> get props => [email];
}

class AuthUpdateProfileEvent extends AuthEvent {
  final String? displayName;
  final String? photoUrl;
  final DateTime? birthDate;
  final Map<String, dynamic>? preferences;
  
  AuthUpdateProfileEvent({
    this.displayName,
    this.photoUrl,
    this.birthDate,
    this.preferences,
  });
  
  @override
  List<Object?> get props => [displayName, photoUrl, birthDate, preferences];
}

class AuthChangeEmailEvent extends AuthEvent {
  final String newEmail;
  final String password;
  
  AuthChangeEmailEvent({
    required this.newEmail,
    required this.password,
  });
  
  @override
  List<Object?> get props => [newEmail, password];
}

class AuthChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  
  AuthChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
  
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class AuthDeleteAccountEvent extends AuthEvent {
  final String password;
  
  AuthDeleteAccountEvent({required this.password});
  
  @override
  List<Object?> get props => [password];
}

// States
@immutable
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class AuthSuccess extends AuthState {
  final String message;
  
  AuthSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription? _authSubscription;
  
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    _authSubscription = authRepository.authStateChanges.listen(
      (User? user) {
        if (user != null) {
          add(AuthCheckStatusEvent());
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
    
    on<AuthCheckStatusEvent>(_onAuthCheckStatus);
    on<AuthRegisterEvent>(_onAuthRegister);
    on<AuthLoginEvent>(_onAuthLogin);
    on<AuthLogoutEvent>(_onAuthLogout);
    on<AuthResetPasswordEvent>(_onAuthResetPassword);
    on<AuthUpdateProfileEvent>(_onAuthUpdateProfile);
    on<AuthChangeEmailEvent>(_onAuthChangeEmail);
    on<AuthChangePasswordEvent>(_onAuthChangePassword);
    on<AuthDeleteAccountEvent>(_onAuthDeleteAccount);
  }
  
  Future<void> _onAuthCheckStatus(
    AuthCheckStatusEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      if (authRepository.isAuthenticated) {
        final userModel = await authRepository.getCurrentUserModel();
        
        if (userModel != null) {
          emit(AuthAuthenticated(userModel));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication status: $e'));
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onAuthRegister(
    AuthRegisterEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final userModel = await authRepository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
        birthDate: event.birthDate,
      );
      
      emit(AuthAuthenticated(userModel));
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
    }
  }
  
  Future<void> _onAuthLogin(
    AuthLoginEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      final userModel = await authRepository.login(
        email: event.email,
        password: event.password,
      );
      
      emit(AuthAuthenticated(userModel));
    } catch (e) {
      emit(AuthError('Login failed: $e'));
    }
  }
  
  Future<void> _onAuthLogout(
    AuthLogoutEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      await authRepository.logout();
      
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: $e'));
    }
  }
  
  Future<void> _onAuthResetPassword(
    AuthResetPasswordEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      await authRepository.resetPassword(event.email);
      
      emit(AuthSuccess('Password reset email sent!'));
    } catch (e) {
      emit(AuthError('Password reset failed: $e'));
    }
  }
  
  Future<void> _onAuthUpdateProfile(
    AuthUpdateProfileEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentState = state;
      
      if (currentState is AuthAuthenticated) {
        emit(AuthLoading());
        
        await authRepository.updateUserProfile(
          displayName: event.displayName,
          photoUrl: event.photoUrl,
          birthDate: event.birthDate,
          preferences: event.preferences,
        );
        
        final updatedUser = await authRepository.getCurrentUserModel();
        
        if (updatedUser != null) {
          emit(AuthAuthenticated(updatedUser));
          emit(AuthSuccess('Profile updated successfully!'));
        } else {
          emit(currentState);
          emit(AuthError('Failed to get updated user data'));
        }
      }
    } catch (e) {
      emit(AuthError('Update profile failed: $e'));
    }
  }
  
  Future<void> _onAuthChangeEmail(
    AuthChangeEmailEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentState = state;
      
      if (currentState is AuthAuthenticated) {
        emit(AuthLoading());
        
        await authRepository.changeEmail(event.newEmail, event.password);
        
        final updatedUser = await authRepository.getCurrentUserModel();
        
        if (updatedUser != null) {
          emit(AuthAuthenticated(updatedUser));
          emit(AuthSuccess('Email updated successfully!'));
        } else {
          emit(currentState);
          emit(AuthError('Failed to get updated user data'));
        }
      }
    } catch (e) {
      emit(AuthError('Change email failed: $e'));
    }
  }
  
  Future<void> _onAuthChangePassword(
    AuthChangePasswordEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentState = state;
      
      emit(AuthLoading());
      
      await authRepository.changePassword(
        event.currentPassword, 
        event.newPassword,
      );
      
      emit(currentState);
      emit(AuthSuccess('Password updated successfully!'));
    } catch (e) {
      emit(AuthError('Change password failed: $e'));
    }
  }
  
  Future<void> _onAuthDeleteAccount(
    AuthDeleteAccountEvent event, 
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());
      
      await authRepository.deleteAccount(event.password);
      
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Delete account failed: $e'));
    }
  }
  
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
