import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Exercise01-Lab09",
      home: ExampleButtons(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Các loại nút')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                showMessage(context, 'Text Button: Xóa dữ liệu');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 20),
                padding: const EdgeInsets.all(20.0),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
              child: const Text("Xóa dữ liệu"),
            ),
            TextButton.icon(
              onPressed: () {
                showMessage(context, 'Text Button Icon: Báo thức');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.all(20.0),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                textStyle: TextStyle(fontSize: 20.0),
              ),
              icon: const Icon(Icons.access_alarm),
              label: Text('Báo thức'),
            ),
            ElevatedButton(
              onPressed: () {
                showMessage(context, 'ElevatedButton: Cập nhật');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.yellow,
                backgroundColor: Colors.brown,
                textStyle: const TextStyle(fontSize: 20.0),
                padding: const EdgeInsets.all(20.0),
                elevation: 10,
              ),
              child: const Text('Cập nhật'),
            ),
            OutlinedButton(
              onPressed: () {
                showMessage(context, 'Outlined Button: Thoát');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(20.0),
                textStyle: TextStyle(fontSize: 20.0),
                side: BorderSide(width: 5, color: Colors.green),
              ),
              child: Text('Thoát'),
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
