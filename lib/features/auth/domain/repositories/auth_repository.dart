import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/user_model.dart';

/// Repository interface for authentication and user management
abstract class AuthRepository {
  // Stream of authentication state changes
  Stream<User?> get authStateChanges;
  
  // Get the current Firebase user
  User? get currentUser;
  
  // Check if user is authenticated
  bool get isAuthenticated;
  
  // Get the current user model from Firestore/local storage
  Future<UserModel?> getCurrentUserModel();
  
  // Register a new user
  Future<UserModel> register({
    required String email, 
    required String password,
    String? displayName,
    DateTime? birthDate,
  });
  
  // Login with email and password
  Future<UserModel> login({
    required String email, 
    required String password,
  });
  
  // Logout the current user
  Future<void> logout();
  
  // Send password reset email
  Future<void> resetPassword(String email);
  
  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    Map<String, dynamic>? preferences,
  });
  
  // Change user's email
  Future<void> changeEmail(String newEmail, String password);
  
  // Change user's password
  Future<void> changePassword(String currentPassword, String newPassword);
  
  // Delete user account
  Future<void> deleteAccount(String password);
}
