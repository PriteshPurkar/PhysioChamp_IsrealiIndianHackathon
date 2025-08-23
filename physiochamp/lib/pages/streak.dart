import 'package:flutter/material.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Streaks"),
      ),
      body: const Center(
        child: Text(
          "Streak tracking coming soon!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
