import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../widgets/project_item_card.dart';
import '../features/projects/presentation/widgets/projects_overview_card.dart';
import 'authentication_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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
    final daysSince = now.difference(birthday).inDays;
    
    // Return just the number of days
    return daysSince.toString();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final User? user = FirebaseAuth.instance.currentUser;
    final String greeting = _getTimeOfDayGreeting();

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<Map<String, dynamic>?>( // Use StreamBuilder for user data
                stream: _firestoreService.getUserData(),
                builder: (context, snapshot) {
                  String userName = user?.email?.split('@')[0] ?? 'User';
                  DateTime? birthday;
                  String birthdayMessage = '';

                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!;
                    userName = userData['name'] ?? userName; // Use name from data if available
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
} 