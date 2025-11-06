// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/survey_data_point.dart';

class StorageService {
  static const _fileName = 'schoolyard_map_data.json';

  // Lấy đường dẫn file local
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  // Đọc tất cả các điểm dữ liệu từ file
  Future<List<SurveyDataPoint>> readDataPoints() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      final List<dynamic> jsonData = json.decode(contents);
      return jsonData.map((item) => SurveyDataPoint.fromJson(item)).toList();
    } catch (e) {
      print("Error reading data: $e");
      return [];
    }
  }

  // Ghi một điểm dữ liệu mới vào file
  Future<void> writeDataPoint(SurveyDataPoint newDataPoint) async {
    try {
      final file = await _localFile;
      // Đọc dữ liệu cũ
      final List<SurveyDataPoint> existingPoints = await readDataPoints();
      // Thêm điểm mới
      existingPoints.add(newDataPoint);
      // Chuyển toàn bộ danh sách thành JSON
      final String jsonString = json.encode(existingPoints.map((p) => p.toJson()).toList());
      // Ghi lại vào file
      await file.writeAsString(jsonString);
    } catch (e) {
      print("Error writing data: $e");
    }
  }
}