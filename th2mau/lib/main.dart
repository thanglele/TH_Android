import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise02-Lab09',
      home: MyHomePage(title: 'Hồ sơ giảng viên'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  String title;
  MyHomePage({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 20),
                  children: [
                    TextSpan(text: 'Xin chào: '),
                    TextSpan(
                      text: 'Chim Canh Cut!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/chimcanhcut.jpg'),
                radius: 120,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Họ và tên: Chim Canh Cut'),
                  const Text('Điện thoại: 0888999888'),
                  const Text('Email: chimcanhcut@vietcodedi.com'),
                  const Text('Chuyên ngành: HTTT'),
                  const Text('website: https://vietcodedi.com'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showMessage(context, 'Thông tin chi tiết');
                        },
                        child: const Text('Xem chi tiết'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showMessage(context, 'Chỉnh sửa hồ sơ');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Chỉnh sửa hồ sơ'),
                      ),
                    ],
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hồ sơ giảng viên'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
