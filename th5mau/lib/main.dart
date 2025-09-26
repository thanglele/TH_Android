import 'package:demoex/models/contact.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Exercise05-lab09",
      home: Exercise05(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Exercise05 extends StatelessWidget {
  List<Contact> contacts = List.generate(
    20,
    (index) => Contact(
      index,
      'MyContact $index',
      'assets/images/contact.png',
      '088899988$index',
    ),
  );
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text('CONTACTS')),
        body: Container(
          padding: EdgeInsets.all(10),
          child: TabBarView(
            children: [
              Text('Contact yêu thích'),
              Text('Contact gọi gần đây'),
              ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.asset('assets/images/contact.jpg'),
                    title: Text(contacts[index].name),
                    subtitle: Text(contacts[index].phone),
                    trailing: TextButton(
                      onPressed: () {},
                      child: Icon(Icons.call),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: const Material(
          color: Colors.red,
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Favourites'),
              Tab(icon: Icon(Icons.recent_actors), text: 'Recent'),
              Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
            ],
          ),
        ),
      ),
    );
  }
}
