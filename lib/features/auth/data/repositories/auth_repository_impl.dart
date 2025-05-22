import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;
  
  AuthRepositoryImpl(this._firebaseService, this._localStorageService);
  
  @override
  Stream<User?> get authStateChanges => _firebaseService.auth.authStateChanges();
  
  @override
  User? get currentUser => _firebaseService.auth.currentUser;
  
  @override
  bool get isAuthenticated => currentUser != null;
  
  @override
  Future<UserModel?> getCurrentUserModel() async {
    if (!isAuthenticated) return null;
    
    try {
      // Check local storage first
      final userData = _localStorageService.getUser();
      if (userData != null) {
        return UserModel.fromJson(userData);
      }
      
      // If not in local storage, fetch from Firestore
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        final userModel = UserModel.fromFirebase(userDoc.data()!);
        
        // Save to local storage for offline access
        await _localStorageService.saveUser(userModel.toJson());
        
        return userModel;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }
  
  @override
  Future<UserModel> register({
    required String email, 
    required String password,
    String? displayName,
    DateTime? birthDate,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }
      
      // Update display name if provided
      if (displayName != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }
      
      // Create user document in Firestore
      final now = DateTime.now();
      final userData = {
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'photoURL': null,
        'createdAt': now,
        'lastLogin': now,
        'birthDate': birthDate,
        'preferences': {},
      };
      
      await _firebaseService.firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);
      
      // Create user model
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        photoUrl: null,
        createdAt: now,
        lastLogin: now,
        birthDate: birthDate,
        preferences: {},
      );
      
      // Save to local storage
      await _localStorageService.saveUser(userModel.toJson());
      
      return userModel;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  
  @override
  Future<UserModel> login({
    required String email, 
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Update last login time
      final now = DateTime.now();
      await _firebaseService.firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({'lastLogin': now});
      
      // Get user data from Firestore
      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }
      
      final userData = userDoc.data()!;
      userData['lastLogin'] = now; // Update the last login time
      
      // Create user model
      final userModel = UserModel.fromFirebase(userData);
      
      // Save to local storage if remember me is enabled
      if (rememberMe) {
        await _localStorageService.saveUser(userModel.toJson());
      } else {
        await _localStorageService.clearAllData();
      }
      
      return userModel;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      await _firebaseService.auth.signOut();
      await _localStorageService.clearAllData();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
  
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
  
  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      final updates = <String, dynamic>{};
      
      // Update display name in Firebase Auth if provided
      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
        updates['displayName'] = displayName;
      }
      
      // Update photo URL in Firebase Auth if provided
      if (photoUrl != null) {
        await currentUser!.updatePhotoURL(photoUrl);
        updates['photoURL'] = photoUrl;
      }
      
      // Add birth date to updates if provided
      if (birthDate != null) {
        updates['birthDate'] = birthDate;
      }
      
      // Add preferences to updates if provided
      if (preferences != null) {
        updates['preferences'] = preferences;
      }
      
      if (updates.isNotEmpty) {
        // Update user document in Firestore
        await _firebaseService.firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(updates);
        
        // Update local storage
        final userData = _localStorageService.getUser();
        if (userData != null) {
          userData.addAll(updates);
          await _localStorageService.saveUser(userData);
        }
      }
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }
  
  @override
  Future<void> changeEmail(String newEmail, String password) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Update email in Firebase Auth
      await currentUser!.updateEmail(newEmail);
      
      // Update email in Firestore
      await _firebaseService.firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'email': newEmail});
      
      // Update local storage
      final userData = _localStorageService.getUser();
      if (userData != null) {
        userData['email'] = newEmail;
        await _localStorageService.saveUser(userData);
      }
    } catch (e) {
      throw Exception('Change email failed: $e');
    }
  }
  
  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      // Update password in Firebase Auth
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Change password failed: $e');
    }
  }
  
  @override
  Future<void> deleteAccount(String password) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      
      final uid = currentUser!.uid;
      
      // Delete user data from Firestore
      await _deleteUserData(uid);
      
      // Delete user from Firebase Auth
      await currentUser!.delete();
      
      // Clear local storage
      await _localStorageService.clearAllData();
    } catch (e) {
      throw Exception('Delete account failed: $e');
    }
  }
  
  // Helper method to delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    // Delete the main user document
    await _firebaseService.firestore.collection('users').doc(userId).delete();
    
    // Delete subcollections
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
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();
      
      final batch = _firebaseService.firestore.batch();
      var counter = 0;
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        counter++;
        
        // Firebase limits batch operations to 500
        if (counter >= 400) {
          await batch.commit();
          counter = 0;
        }
      }
      
      if (counter > 0) {
        await batch.commit();
      }
    }
  }
}
