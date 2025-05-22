import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences.dart';

import 'firebase_service.dart';

/// Service for handling authentication-related operations
class AuthService {
  final FirebaseService _firebaseService;
  static const String _rememberMeKey = 'remember_me';
  
  AuthService(this._firebaseService) {
    // Configure Firebase Auth persistence
    _auth.setPersistence(Persistence.LOCAL);
    _initializeAuthState();
  }
  
  // Get the Firebase Auth instance
  FirebaseAuth get _auth => _firebaseService.auth;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current user ID
  String? get currentUserId => currentUser?.uid;
  
  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Initialize auth state
  Future<void> _initializeAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (!rememberMe) {
        await _auth.signOut();
      }
    } catch (e) {
      print('Error initializing auth state: $e');
    }
  }
  
  // Register with email and password
  Future<User?> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore and update profile
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
        await _createUserDocument(userCredential.user!);
      }
      
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password, {bool rememberMe = true}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      
      // Update last login
      await updateLastLogin();
      
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if remember me is enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Clear remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, false);
      
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _deleteUserData(user.uid);
        // Then delete the account
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Create initial user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firebaseService.firestore.collection('users').doc(user.uid);
    
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': DateTime.now(),
      'lastLogin': DateTime.now(),
    };
    
    await userDoc.set(userData);
  }
  
  // Delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    // Delete the main user document
    await _firebaseService.firestore.collection('users').doc(userId).delete();
    
    // Delete subcollections (Firebase doesn't automatically delete subcollections)
    final collections = [
      'projects',
      'tasks',
      'pomodoroSessions',
      'journalEntries',
      'habits',
      'principles',
      'flashcards',
      'goals',
    ];
    
    for (final collection in collections) {
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();
      
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
  
  // Update user's last login timestamp
  Future<void> updateLastLogin() async {
    if (currentUser != null) {
      await _firebaseService.firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'lastLogin': DateTime.now(),
      });
    }
  }
}
