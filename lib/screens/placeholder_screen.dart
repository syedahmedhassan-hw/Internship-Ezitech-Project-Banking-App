import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title screen — build out the UI and Firestore logic here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ),
    );
  }
}
