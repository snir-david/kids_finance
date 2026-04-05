import 'package:flutter/material.dart';

class ChildPinScreen extends StatelessWidget {
  const ChildPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
      body: const Center(
        child: Text('Child PIN Screen - To be implemented by Fury'),
      ),
    );
  }
}
