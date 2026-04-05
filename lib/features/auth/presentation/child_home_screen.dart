import 'package:flutter/material.dart';

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Buckets'),
      ),
      body: const Center(
        child: Text('Child Home Screen - To be implemented by Rhodey'),
      ),
    );
  }
}
