import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String userId;
  final String? color;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.userId,
    this.color,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Safely handle createdAt which could be Timestamp or String
    DateTime createdAtDate;
    final createdAtData = data['createdAt'];
    if (createdAtData is Timestamp) {
      createdAtDate = createdAtData.toDate();
    } else if (createdAtData is String) {
      createdAtDate = DateTime.parse(createdAtData);
    } else {
      // Fallback to current date or throw error if createdAt is crucial
      createdAtDate = DateTime.now();
      print('Warning: Invalid createdAt type in Firestore for document ${doc.id}');
    }

    return Project(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdAt: createdAtDate,
      userId: data['userId'] ?? '',
      color: data['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'color': color,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'] ?? '',
      color: map['color'],
    );
  }
} 