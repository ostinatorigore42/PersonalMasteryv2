import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user in the app
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime? birthDate;
  final Map<String, dynamic> preferences;
  
  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.birthDate,
    this.preferences = const {},
  });
  
  // Create from Firebase User and additional data
  factory UserModel.fromFirebase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      preferences: data['preferences'] as Map<String, dynamic>? ?? {},
    );
  }
  
  // Convert to Map for Firebase storage
  Map<String, dynamic> toFirebase() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'birthDate': birthDate,
      'preferences': preferences,
    };
  }
  
  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'birthDate': birthDate?.toIso8601String(),
      'preferences': preferences,
    };
  }
  
  // Create from local storage Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoURL'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate'] as String) : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
  
  // Copy with method for updating user properties
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? birthDate,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      birthDate: birthDate ?? this.birthDate,
      preferences: preferences ?? this.preferences,
    );
  }
  
  // Calculate age in days from birth date
  int? get ageInDays {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(birthDate!.year, birthDate!.month, birthDate!.day))
        .inDays + 1;
  }
}
