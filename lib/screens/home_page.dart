import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../widgets/project_item_card.dart';
import '../features/projects/presentation/widgets/projects_overview_card.dart';
import 'authentication_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_mastery/core/constants/route_constants.dart';
import 'package:personal_mastery/features/calendar/presentation/pages/calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Function to calculate days since birthday
  String _getDaysSinceBirthday(DateTime? birthday) {
    if (birthday == null) return '';

    final now = DateTime.now();
    final daysSince = now.difference(birthday).inDays + 1; // Add +1 to include the current day
    
    // Return just the number of days
    return daysSince.toString();
  }

    @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final User? user = FirebaseAuth.instance.currentUser;
    final String greeting = _getTimeOfDayGreeting();

    print('DEBUG: HomePage current user: \\${user?.uid} email: \\${user?.email}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  // Debug: Show UID
                  Text(
                    'UID: \\${user?.uid ?? 'null'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Projects & Tasks'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Pomodoro Timer'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Journal'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Knowledge'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Goals'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Stack( // Use a Stack to layer the body content and the buttons
        children: [
          SingleChildScrollView( // Your existing main content
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StreamBuilder<Map<String, dynamic>?>(
                    stream: _firestoreService.getUserData(),
                    builder: (context, snapshot) {
                      String userName = user?.email?.split('@')[0] ?? 'User';
                      DateTime? birthday;
                      String birthdayMessage = '';

                      if (snapshot.hasData && snapshot.data != null) {
                        final userData = snapshot.data!;
                        userName = userData['name'] ?? userName;
                        if (userData['birthday'] is Timestamp) {
                          birthday = (userData['birthday'] as Timestamp).toDate();
                          final days = _getDaysSinceBirthday(birthday);
                          if (days.isNotEmpty) {
                            birthdayMessage = 'It is Day $days of your life.';
                          }
                        }
                      }

                      return Text(
                        '$greeting, $userName. $birthdayMessage',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                ProjectsOverviewCard(),
              ],
            ),
          ),
          Align( // Align the Row of buttons to the bottom center
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // Add some padding from the bottom
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the row of buttons
                mainAxisSize: MainAxisSize.min, // Make the row take minimum space
                children: [
                  // Existing Home Button
                  FloatingActionButton(
                    heroTag: 'homeFAB', // Add a unique heroTag
                    onPressed: () {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.home, color: Colors.white),
                    elevation: 4.0,
                    shape: const CircleBorder(),
                  ),
                  const SizedBox(width: 16.0), // Add space between buttons
                  // New Calendar Button
                  FloatingActionButton(
                    heroTag: 'calendarFAB', // Add a unique heroTag
                    onPressed: () {
                      print('Calendar button pressed');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CalendarPage(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blueAccent, // Match the Home button style
                    child: const Icon(Icons.calendar_today, color: Colors.white), // Calendar icon
                    elevation: 4.0,
                    shape: const CircleBorder(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}