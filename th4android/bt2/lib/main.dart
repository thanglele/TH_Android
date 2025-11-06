import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Balance Ball Game',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      ),
      home: const BalanceGameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Màn hình chính của game, sử dụng StatefulWidget để quản lý trạng thái
class BalanceGameScreen extends StatefulWidget {
  const BalanceGameScreen({super.key});

  @override
  State<BalanceGameScreen> createState() => _BalanceGameScreenState();
}

class _BalanceGameScreenState extends State<BalanceGameScreen> {
  // Kích thước của quả bi và đích
  static const double _ballSize = 50.0;
  static const double _targetSize = 50.0;

  // Tọa độ của quả bi và đích
  double _ballX = 0, _ballY = 0;
  double _targetX = 0, _targetY = 0;

  // Biến lưu trữ giá trị đầu vào từ cảm biến để hiển thị
  double _accelerometerX = 0, _accelerometerY = 0, _accelerometerZ = 0;

  // Biến để lắng nghe sự kiện từ cảm biến
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Khởi tạo vị trí ban đầu sau khi widget được build lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetBallPosition();
      _randomizeTargetPosition();
    });

    // Bắt đầu lắng nghe sự kiện từ gia tốc kế
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      // Sử dụng setState để cập nhật giao diện khi có dữ liệu mới
      setState(() {
        // Cập nhật giá trị cảm biến để hiển thị
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;

        // Hệ số điều chỉnh tốc độ lăn của bi
        const double speedMultiplier = 2.5;

        // Cập nhật tọa độ X và Y của quả bi
        // event.x điều khiển chuyển động ngang, event.y điều khiển dọc
        // Dấu trừ (-) để đảo ngược hướng cho tự nhiên hơn
        _ballX -= event.x * speedMultiplier;
        _ballY += event.y * speedMultiplier;

        // Giới hạn để quả bi không đi ra ngoài màn hình
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.top;

        _ballX = _ballX.clamp(0, screenWidth - _ballSize);
        _ballY = _ballY.clamp(0, screenHeight - _ballSize);

        // Kiểm tra điều kiện thắng
        _checkWinCondition();
      });
    });
  }

  // Hàm đặt lại vị trí quả bi về giữa màn hình
  void _resetBallPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

    setState(() {
      _ballX = (screenWidth - _ballSize) / 2;
      _ballY = (screenHeight - _ballSize) / 2;
    });
  }

  // Hàm tạo vị trí ngẫu nhiên cho đích
  void _randomizeTargetPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

    setState(() {
      _targetX = _random.nextDouble() * (screenWidth - _targetSize);
      _targetY = _random.nextDouble() * (screenHeight - _targetSize);
    });
  }

  // Hàm kiểm tra xem quả bi đã chạm đích chưa
  void _checkWinCondition() {
    // Tính toán tọa độ tâm của quả bi và đích
    final ballCenterX = _ballX + _ballSize / 2;
    final ballCenterY = _ballY + _ballSize / 2;
    final targetCenterX = _targetX + _targetSize / 2;
    final targetCenterY = _targetY + _targetSize / 2;

    // Sử dụng định lý Pytago để tính khoảng cách giữa hai tâm
    final distance = sqrt(pow(ballCenterX - targetCenterX, 2) +
        pow(ballCenterY - targetCenterY, 2));

    // Nếu khoảng cách nhỏ hơn bán kính của đích, người chơi thắng
    if (distance < _targetSize / 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chiến thắng!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      // Tạo vị trí mới cho đích để tiếp tục chơi
      _randomizeTargetPosition();
    }
  }

  // Hủy lắng nghe sự kiện khi widget bị loại bỏ để tránh rò rỉ bộ nhớ
  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lăn Bi Thăng Bằng'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Hiển thị giá trị cảm biến
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cảm biến gia tốc:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('X: ${_accelerometerX.toStringAsFixed(2)}'),
                    Text('Y: ${_accelerometerY.toStringAsFixed(2)}'),
                    Text('Z: ${_accelerometerZ.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ),
          // Đích (vị trí thay đổi)
          Positioned(
            left: _targetX,
            top: _targetY,
            child: Container(
              width: _targetSize,
              height: _targetSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade600, width: 4),
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
          // Quả bi (di chuyển theo cảm biến)
          Positioned(
            left: _ballX,
            top: _ballY,
            child: Container(
              width: _ballSize,
              height: _ballSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetBallPosition,
        tooltip: 'Reset vị trí bi',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}