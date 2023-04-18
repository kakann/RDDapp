import 'package:flutter/material.dart';
import 'package:rdd/HomeScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterViz Demo',

      /// TODO Replace with your first screen class name
      home: HomeScreen(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text("My FlutterViz Demo"),
    );
  }
}
