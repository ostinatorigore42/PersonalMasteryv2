import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's projects
  Stream<List<Map<String, dynamic>>> getProjects() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'color': Color(data['color']),
          'minutes': data['minutes'] ?? '0m',
          'tasks': data['tasks'] ?? 0,
        };
      }).toList();
    });
  }

  // Create a new project
  Future<void> createProject({
    required String name,
    required Color color,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .add({
      'name': name,
      'color': color.value,
      'minutes': '0m',
      'tasks': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }
} 