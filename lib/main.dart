import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/authentication_screen.dart';
import 'core/services/firebase_service.dart';
import 'utils/route_constants.dart';
import 'screens/home_page.dart';
import 'core/di/injection_container.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Set Firebase Auth persistence to LOCAL
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    // Initialize your custom FirebaseService after the core Firebase app is initialized
    await FirebaseService.initialize();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final localStorageService = await LocalStorageService.init(prefs);

  setupDependencies(localStorageService);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return MaterialApp(
            title: 'Second Brain - Test Change',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const HomePage(),
          );
        } else {
          return MaterialApp(
            title: 'Second Brain - Test Change',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const AuthenticationScreen(),
          );
        }
      },
    );
  }
} 