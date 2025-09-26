import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise03-Lab09',
      home: BoxGame(title: 'BÔNG TUYẾT MAY MẮN'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BoxGame extends StatefulWidget {
  String title;
  BoxGame({required this.title});
  @override
  State<StatefulWidget> createState() => _MyGameState();
}

class _MyGameState extends State<BoxGame> {
  List<int> buttons = List.generate(25, (index) => index);
  List<Icon> icons = List.generate(25, (index) => Icon(null));
  List<int> result = List.generate(25, (index) => 0);
  int counter = 0;
  String message = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset("assets/images/boxmagic.png", width: 200),
            const Text(
              'Kích vào ô bất kỳ để tìm bông tuyết',
              style: TextStyle(fontSize: 22.0),
            ),
            Wrap(
              spacing: 20.0,
              runSpacing: 10.0,
              children: buttons
                  .map(
                    (e) => FloatingActionButton(
                      onPressed: () {
                        if (result[e] == 0) {
                          var x = Random().nextInt(100) + 1;
                          if (isPrimeNumber(x)) {
                            setState(() {
                              icons[e] = Icon(Icons.ac_unit);
                              result[e] = x;
                              counter++;
                            });
                          } else {
                            setState(() {
                              icons[e] = Icon(Icons.clear_rounded);
                              result[e] = x;
                            });
                          }
                          if (result.where((n) => n == 0).isEmpty) {
                            setState(() {
                              message =
                                  'CHÚC MỪNG BẠN ĐÃ TÌM ĐƯỢC $counter BÔNG TUYẾT';
                            });
                          }
                        }
                      },
                      child: icons[e],
                    ),
                  )
                  .toList(),
            ),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      icons = List.generate(25, (index) => Icon(null));
                      result = List.generate(25, (index) => 0);
                      message = '';
                      counter = 0;
                    });
                  },
                  child: Text("Chơi lại"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: Text("Thoát"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool isPrimeNumber(int number) {
    if (number == 1) return false;
    if (number == 2) return true;
    int limit = sqrt(number).ceil();
    for (int i = 2; i <= limit; ++i) {
      if (number % i == 0) return false;
    }
    return true;
  }
}
