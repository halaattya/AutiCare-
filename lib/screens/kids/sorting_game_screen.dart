import 'package:flutter/material.dart';


class SortingGameScreen extends StatelessWidget {
  const SortingGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3A66A),
        title: const Text('Sorting Game'),
      ),
      body: const Center(
        child: Text(
          'Sorting Game placeholder',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
