import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  final FirebaseFirestore _firestore;

  GoalRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final snapshot = await _firestore.collection('goals').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get goals: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getGoalDetails(String goalId) async {
    try {
      final doc = await _firestore.collection('goals').doc(goalId).get();
      if (!doc.exists) {
        throw Exception('Goal not found');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw Exception('Failed to get goal details: $e');
    }
  }

  @override
  Future<void> createGoal(Map<String, dynamic> goal) async {
    try {
      await _firestore.collection('goals').add(goal);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  @override
  Future<void> updateGoal(String goalId, Map<String, dynamic> goal) async {
    try {
      await _firestore.collection('goals').doc(goalId).update(goal);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      await _firestore.collection('goals').doc(goalId).delete();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }
} 