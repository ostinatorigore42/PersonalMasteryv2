import 'package:hive/hive.dart';

/// Model representing daily focus information
class DailyFocusModel {
  final DateTime date;
  final String greeting;
  final int ageInDays;
  final List<String> topGoalIds;
  final List<String> suggestedTaskIds;
  final double? yesterdayAverageRating;
  final List<String>? motivationalQuotes;
  
  DailyFocusModel({
    required this.date,
    required this.greeting,
    required this.ageInDays,
    required this.topGoalIds,
    required this.suggestedTaskIds,
    this.yesterdayAverageRating,
    this.motivationalQuotes,
  });
  
  // Convert to Map for Firebase storage
  Map<String, dynamic> toFirebase() {
    return {
      'date': date,
      'greeting': greeting,
      'ageInDays': ageInDays,
      'topGoalIds': topGoalIds,
      'suggestedTaskIds': suggestedTaskIds,
      'yesterdayAverageRating': yesterdayAverageRating,
      'motivationalQuotes': motivationalQuotes,
    };
  }
  
  // Create from Firebase data
  factory DailyFocusModel.fromFirebase(Map<String, dynamic> data) {
    return DailyFocusModel(
      date: (data['date'] as dynamic).toDate(),
      greeting: data['greeting'] as String,
      ageInDays: data['ageInDays'] as int,
      topGoalIds: List<String>.from(data['topGoalIds'] ?? []),
      suggestedTaskIds: List<String>.from(data['suggestedTaskIds'] ?? []),
      yesterdayAverageRating: data['yesterdayAverageRating'] as double?,
      motivationalQuotes: data['motivationalQuotes'] != null
          ? List<String>.from(data['motivationalQuotes'])
          : null,
    );
  }
  
  // Convert to Map for local storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'greeting': greeting,
      'ageInDays': ageInDays,
      'topGoalIds': topGoalIds,
      'suggestedTaskIds': suggestedTaskIds,
      'yesterdayAverageRating': yesterdayAverageRating,
      'motivationalQuotes': motivationalQuotes,
    };
  }
  
  // Create from local storage Map
  factory DailyFocusModel.fromJson(Map<String, dynamic> json) {
    return DailyFocusModel(
      date: DateTime.parse(json['date'] as String),
      greeting: json['greeting'] as String,
      ageInDays: json['ageInDays'] as int,
      topGoalIds: List<String>.from(json['topGoalIds'] ?? []),
      suggestedTaskIds: List<String>.from(json['suggestedTaskIds'] ?? []),
      yesterdayAverageRating: json['yesterdayAverageRating'] as double?,
      motivationalQuotes: json['motivationalQuotes'] != null
          ? List<String>.from(json['motivationalQuotes'])
          : null,
    );
  }
  
  // Copy with method for updating properties
  DailyFocusModel copyWith({
    DateTime? date,
    String? greeting,
    int? ageInDays,
    List<String>? topGoalIds,
    List<String>? suggestedTaskIds,
    double? yesterdayAverageRating,
    List<String>? motivationalQuotes,
  }) {
    return DailyFocusModel(
      date: date ?? this.date,
      greeting: greeting ?? this.greeting,
      ageInDays: ageInDays ?? this.ageInDays,
      topGoalIds: topGoalIds ?? this.topGoalIds,
      suggestedTaskIds: suggestedTaskIds ?? this.suggestedTaskIds,
      yesterdayAverageRating: yesterdayAverageRating ?? this.yesterdayAverageRating,
      motivationalQuotes: motivationalQuotes ?? this.motivationalQuotes,
    );
  }
}
