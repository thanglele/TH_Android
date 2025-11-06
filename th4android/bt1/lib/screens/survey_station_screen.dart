// lib/screens/survey_station_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/survey_data_point.dart';
import '../services/storage_service.dart';

class SurveyStationScreen extends StatefulWidget {
  const SurveyStationScreen({super.key});

  @override
  State<SurveyStationScreen> createState() => _SurveyStationScreenState();
}

class _SurveyStationScreenState extends State<SurveyStationScreen> {
  final StorageService _storageService = StorageService();
  
  // Dữ liệu cảm biến
  double _luxValue = 0;
  double _activityMagnitude = 0;
  double _magneticFieldMagnitude = 0;

  // Stream Subscriptions để quản lý
  // <<< SỬA LỖI: Đưa _lightSensorSubscription trở lại
  StreamSubscription? _lightSensorSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _magnetometerSubscription;
  
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _startListeningToSensors();
    _handleLocationPermission();
  }

  @override
  void dispose() {
    // Huỷ đăng ký các stream để tránh memory leak
    // <<< SỬA LỖI: Hủy subscription một cách chính xác
    _lightSensorSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }
  
  void _startListeningToSensors() {
    // Cảm biến ánh sáng
    // <<< SỬA LỖI: Gọi luxStream() không có tham số và gán vào subscription
    try {
      _lightSensorSubscription = LightSensor.luxStream().listen((int lux) {
          if (!mounted) return;
          setState(() {
            _luxValue = lux.toDouble();
          });
      });
    } catch (e) {
      print("Could not start light sensor: $e");
    }

    // Gia tốc kế
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _activityMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      });
    });
    
    // Từ kế
     _magnetometerSubscription = magnetometerEventStream().listen((event) {
      if (!mounted) return;
      setState(() {
        _magneticFieldMagnitude = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      });
    });
  }
  
  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dịch vụ định vị đã bị tắt. Vui lòng bật lại.')));
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn, không thể yêu cầu lại.')));
      return;
    }
  }

  Future<void> _recordData() async {
    setState(() => _isRecording = true);
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final dataPoint = SurveyDataPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        lightIntensity: _luxValue,
        activityLevel: _activityMagnitude,
        magneticField: _magneticFieldMagnitude,
        timestamp: DateTime.now(),
      );

      await _storageService.writeDataPoint(dataPoint);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã ghi dữ liệu thành công!'), backgroundColor: Colors.green),
        );
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi ghi dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạm Khảo sát'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSensorCard(
              icon: Icons.wb_sunny,
              title: 'Cường độ Ánh sáng',
              value: '${_luxValue.toStringAsFixed(2)} lux',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildSensorCard(
              icon: Icons.directions_run,
              title: 'Độ "Năng động"',
              value: _activityMagnitude.toStringAsFixed(2),
              color: Colors.red,
            ),
             const SizedBox(height: 16),
            _buildSensorCard(
              icon: Icons.compass_calibration,
              title: 'Cường độ Từ trường',
              value: '${_magneticFieldMagnitude.toStringAsFixed(2)} µT',
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isRecording ? null : _recordData,
              icon: _isRecording 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                : const Icon(Icons.save),
              label: Text(_isRecording ? 'Đang lấy dữ liệu...' : 'Ghi Dữ liệu tại Điểm này'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}