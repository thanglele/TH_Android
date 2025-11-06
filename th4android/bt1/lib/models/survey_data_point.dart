// lib/models/survey_data_point.dart
import 'dart:convert';

class SurveyDataPoint {
  final double latitude;
  final double longitude;
  final double lightIntensity;
  final double activityLevel;
  final double magneticField;
  final DateTime timestamp;

  SurveyDataPoint({
    required this.latitude,
    required this.longitude,
    required this.lightIntensity,
    required this.activityLevel,
    required this.magneticField,
    required this.timestamp,
  });

  // Chuyển đối tượng thành một Map để encode ra JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'lightIntensity': lightIntensity,
      'activityLevel': activityLevel,
      'magneticField': magneticField,
      'timestamp': timestamp.toIso8601String(), // Chuẩn hoá thời gian
    };
  }

  // Tạo đối tượng từ một Map (khi decode từ JSON)
  factory SurveyDataPoint.fromJson(Map<String, dynamic> json) {
    return SurveyDataPoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
      lightIntensity: json['lightIntensity'],
      activityLevel: json['activityLevel'],
      magneticField: json['magneticField'],
      timestamp: DateTime.parse(json['timestamp']), // Chuyển chuỗi về DateTime
    );
  }
}