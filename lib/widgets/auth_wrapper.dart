import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:simple_productivity_app/services/auth_service.dart';
// import 'package:simple_productivity_app/main.dart'; // Remove import for MyApp
import 'package:simple_productivity_app/screens/authentication_screen.dart'; // Import the new AuthenticationScreen
import 'package:simple_productivity_app/screens/home_page.dart'; // Import the new HomePage

// Placeholder Authentication Screen (you will replace this with your actual Login/Signup UI)
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
      ),
      body: Center(
        child: Text('Auth Screen Placeholder'),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AuthService stream
    final _authService = AuthService();
    final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Get Firestore instance

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Initial loading state while checking auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if the user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, now fetch user data from Firestore
          User user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _firestore.collection('users').doc(user.uid).get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                // Loading state while fetching user document
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userDocSnapshot.hasError) {
                // Handle error fetching user document
                print('Error fetching user document: ${userDocSnapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Text('Error loading user data: ${userDocSnapshot.error}'),
                  ),
                );
              }

              if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                // User document loaded successfully, show the main app content
                // You can potentially pass userDocSnapshot.data.data() down to MyApp
                // Pass the user data to the HomePage
                return HomePage(userData: userDocSnapshot.data!.data()!);
              } else {
                // User is authenticated but no user document found in Firestore
                 print('Authenticated user found, but no user document in Firestore.');
                 // This shouldn't happen with the signup logic, but good to handle
                 // Maybe redirect to a profile creation page or show an error
                return Scaffold(
                   body: Center(
                     child: Text('User data not found. Please contact support.'),
                   ),
                 );
              }
            },
          );
        } else {
          // User is not logged in, show the authentication screen
          return const AuthenticationScreen(); // Your authentication UI
        }
      },
    );
  }
} 