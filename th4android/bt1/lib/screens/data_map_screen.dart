// lib/screens/data_map_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/survey_data_point.dart';
import '../services/storage_service.dart';

class DataMapScreen extends StatefulWidget {
  const DataMapScreen({super.key});

  @override
  State<DataMapScreen> createState() => _DataMapScreenState();
}

class _DataMapScreenState extends State<DataMapScreen> {
  final StorageService _storageService = StorageService();
  late Future<List<SurveyDataPoint>> _dataPointsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataPointsFuture = _storageService.readDataPoints();
    });
  }

  // Hàm ánh xạ giá trị sang màu sắc
  Color _getLightColor(double lux) {
    // Giả sử thang đo từ 0 đến 10000 lux
    final intensity = (lux / 10000).clamp(0.0, 1.0);
    return Color.lerp(Colors.yellow.shade100, Colors.yellow.shade900, intensity)!;
  }

  Color _getActivityColor(double magnitude) {
    // Trọng lực chuẩn là ~9.8. Ta xem xét sự thay đổi so với nó.
    // Giả sử thang đo từ 9.8 (đứng yên) đến 20 (rung lắc mạnh)
    final intensity = ((magnitude - 9.8) / 10.2).clamp(0.0, 1.0);
    return Color.lerp(Colors.red.shade100, Colors.red.shade900, intensity)!;
  }

  Color _getMagneticColor(double magnitude) {
    // Từ trường trái đất ~30-60 µT.
    // Giả sử thang đo từ 20 đến 150 µT
    final intensity = ((magnitude - 20) / 130).clamp(0.0, 1.0);
    return Color.lerp(Colors.blue.shade100, Colors.blue.shade900, intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Dữ liệu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          )
        ],
      ),
      body: FutureBuilder<List<SurveyDataPoint>>(
        future: _dataPointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có dữ liệu.\nHãy qua tab "Trạm Khảo sát" để ghi điểm đầu tiên.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final dataPoints = snapshot.data!;
          // Sắp xếp để điểm mới nhất lên đầu
          dataPoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: dataPoints.length,
            itemBuilder: (context, index) {
              final point = dataPoints[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vị trí: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(point.timestamp)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDataVisual(
                            icon: Icons.wb_sunny,
                            value: '${point.lightIntensity.toStringAsFixed(0)} lux',
                            color: _getLightColor(point.lightIntensity),
                          ),
                          _buildDataVisual(
                            icon: Icons.directions_run,
                            value: point.activityLevel.toStringAsFixed(1),
                            color: _getActivityColor(point.activityLevel),
                          ),
                          _buildDataVisual(
                            icon: Icons.compass_calibration,
                            value: '${point.magneticField.toStringAsFixed(1)} µT',
                            color: _getMagneticColor(point.magneticField),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDataVisual({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}