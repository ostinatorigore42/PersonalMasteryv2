import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: Add methods for sign up, sign in, sign out, etc.

  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
    DateTime? birthday,
  ) async {
    try {
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // Create a new document for the user in the 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': name,
          'createdAt': Timestamp.now(),
          if (birthday != null) 'birthday': Timestamp.fromDate(birthday),
          // Add other initial user data here if needed
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // Re-throw specific Firebase Auth errors for UI to handle
      throw e;
    } catch (e) {
      // Handle other potential errors
      print('Error creating user and Firestore document: $e');
      // You might want to throw a generic exception here or handle differently
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Re-throw specific Firebase Auth errors for UI to handle
      throw e;
    } catch (e) {
      // Handle other potential errors
      print('Error signing in: $e');
      // You might want to throw a generic exception here or handle differently
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
} 